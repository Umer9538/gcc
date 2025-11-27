import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

enum WorkflowType {
  documentRequest,
  meetingRequest,
  announcementApproval,
  userRegistration,
  roleChange,
}

enum WorkflowStatus {
  pending,
  inProgress,
  approved,
  rejected,
  completed,
  cancelled,
}

class WorkflowModel {
  final String id;
  final WorkflowType type;
  final String title;
  final String description;
  final String initiatorId;
  final String initiatorName;
  final String? assigneeId;
  final String? assigneeName;
  final WorkflowStatus status;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final List<WorkflowStepModel> steps;
  final int currentStepIndex;

  WorkflowModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.initiatorId,
    required this.initiatorName,
    this.assigneeId,
    this.assigneeName,
    this.status = WorkflowStatus.pending,
    this.data = const {},
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.steps = const [],
    this.currentStepIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'description': description,
      'initiatorId': initiatorId,
      'initiatorName': initiatorName,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'status': status.toString(),
      'data': data,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
      'steps': steps.map((step) => step.toMap()).toList(),
      'currentStepIndex': currentStepIndex,
    };
  }

  factory WorkflowModel.fromMap(Map<String, dynamic> map) {
    return WorkflowModel(
      id: map['id'] ?? '',
      type: WorkflowType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => WorkflowType.documentRequest,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      initiatorId: map['initiatorId'] ?? '',
      initiatorName: map['initiatorName'] ?? '',
      assigneeId: map['assigneeId'],
      assigneeName: map['assigneeName'],
      status: WorkflowStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => WorkflowStatus.pending,
      ),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      steps: (map['steps'] as List<dynamic>?)
          ?.map((step) => WorkflowStepModel.fromMap(step))
          .toList() ?? [],
      currentStepIndex: map['currentStepIndex'] ?? 0,
    );
  }
}

class WorkflowStepModel {
  final String id;
  final String title;
  final String description;
  final String? assigneeId;
  final String? assigneeName;
  final WorkflowStatus status;
  final DateTime? completedAt;
  final String? completedById;
  final String? completedByName;
  final String? notes;

  WorkflowStepModel({
    required this.id,
    required this.title,
    required this.description,
    this.assigneeId,
    this.assigneeName,
    this.status = WorkflowStatus.pending,
    this.completedAt,
    this.completedById,
    this.completedByName,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'status': status.toString(),
      'completedAt': completedAt,
      'completedById': completedById,
      'completedByName': completedByName,
      'notes': notes,
    };
  }

  factory WorkflowStepModel.fromMap(Map<String, dynamic> map) {
    return WorkflowStepModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assigneeId: map['assigneeId'],
      assigneeName: map['assigneeName'],
      status: WorkflowStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => WorkflowStatus.pending,
      ),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      completedById: map['completedById'],
      completedByName: map['completedByName'],
      notes: map['notes'],
    );
  }
}

class WorkflowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();

  // Create a new workflow
  Future<String> createWorkflow({
    required WorkflowType type,
    required String title,
    required String description,
    required String initiatorId,
    required String initiatorName,
    String? assigneeId,
    String? assigneeName,
    Map<String, dynamic> data = const {},
    List<WorkflowStepModel> steps = const [],
  }) async {
    final workflowId = _uuid.v4();

    final workflow = WorkflowModel(
      id: workflowId,
      type: type,
      title: title,
      description: description,
      initiatorId: initiatorId,
      initiatorName: initiatorName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      data: data,
      createdAt: DateTime.now(),
      steps: steps,
    );

    await _firestore
        .collection('workflows')
        .doc(workflowId)
        .set(workflow.toMap());

    // Notify assignee if specified
    if (assigneeId != null && assigneeId != initiatorId) {
      try {
        await _notificationService.sendNotificationToUser(
          userId: assigneeId,
          title: 'New Workflow Assigned',
          body: 'You have been assigned a new workflow: $title',
          type: NotificationType.workflow,
          data: {
            'workflowId': workflowId,
            'type': 'workflow_assigned',
          },
        );
      } catch (e) {
        print('Failed to send workflow assignment notification: $e');
      }
    }

    return workflowId;
  }

  // Update workflow status
  Future<void> updateWorkflowStatus({
    required String workflowId,
    required WorkflowStatus status,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'status': status.toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == WorkflowStatus.completed ||
        status == WorkflowStatus.approved ||
        status == WorkflowStatus.rejected) {
      updates['completedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore
        .collection('workflows')
        .doc(workflowId)
        .update(updates);

    // Notify relevant parties
    final workflow = await getWorkflowById(workflowId);
    if (workflow != null) {
      await _notifyWorkflowStatusChange(workflow, status, notes);
    }
  }

  // Complete a workflow step
  Future<void> completeWorkflowStep({
    required String workflowId,
    required int stepIndex,
    required String completedById,
    required String completedByName,
    String? notes,
  }) async {
    final workflow = await getWorkflowById(workflowId);
    if (workflow == null || stepIndex >= workflow.steps.length) return;

    final steps = List<WorkflowStepModel>.from(workflow.steps);
    steps[stepIndex] = WorkflowStepModel(
      id: steps[stepIndex].id,
      title: steps[stepIndex].title,
      description: steps[stepIndex].description,
      assigneeId: steps[stepIndex].assigneeId,
      assigneeName: steps[stepIndex].assigneeName,
      status: WorkflowStatus.completed,
      completedAt: DateTime.now(),
      completedById: completedById,
      completedByName: completedByName,
      notes: notes,
    );

    final updates = <String, dynamic>{
      'steps': steps.map((step) => step.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Check if this was the last step
    final nextStepIndex = stepIndex + 1;
    if (nextStepIndex >= steps.length) {
      updates['status'] = WorkflowStatus.completed.toString();
      updates['completedAt'] = FieldValue.serverTimestamp();
    } else {
      updates['currentStepIndex'] = nextStepIndex;
      updates['status'] = WorkflowStatus.inProgress.toString();
    }

    await _firestore
        .collection('workflows')
        .doc(workflowId)
        .update(updates);

    // Notify about step completion and next step assignment
    if (nextStepIndex < steps.length) {
      final nextStep = steps[nextStepIndex];
      if (nextStep.assigneeId != null) {
        try {
          await _notificationService.sendNotificationToUser(
            userId: nextStep.assigneeId!,
            title: 'Workflow Step Assigned',
            body: 'Next step in "${workflow.title}": ${nextStep.title}',
            type: NotificationType.workflow,
            data: {
              'workflowId': workflowId,
              'stepIndex': nextStepIndex,
              'type': 'workflow_step_assigned',
            },
          );
        } catch (e) {
          print('Failed to send workflow step notification: $e');
        }
      }
    } else {
      // Workflow completed, notify initiator
      try {
        await _notificationService.sendNotificationToUser(
          userId: workflow.initiatorId,
          title: 'Workflow Completed',
          body: 'Your workflow "${workflow.title}" has been completed',
          type: NotificationType.workflow,
          data: {
            'workflowId': workflowId,
            'type': 'workflow_completed',
          },
        );
      } catch (e) {
        print('Failed to send workflow completion notification: $e');
      }
    }
  }

  // Get workflows for user
  Stream<List<WorkflowModel>> getWorkflowsForUser(String userId) {
    return _firestore
        .collection('workflows')
        .where('initiatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkflowModel.fromMap(doc.data()))
            .toList())
        .handleError((error) {
          print('Error getting workflows for user: $error');
          return <WorkflowModel>[];
        });
  }

  // Get workflows assigned to user
  Stream<List<WorkflowModel>> getAssignedWorkflows(String userId) {
    return _firestore
        .collection('workflows')
        .where('assigneeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkflowModel.fromMap(doc.data()))
            .toList())
        .handleError((error) {
          print('Error getting assigned workflows: $error');
          return <WorkflowModel>[];
        });
  }

  // Get pending workflows
  Stream<List<WorkflowModel>> getPendingWorkflows() {
    return _firestore
        .collection('workflows')
        .where('status', isEqualTo: WorkflowStatus.pending.toString())
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkflowModel.fromMap(doc.data()))
            .toList())
        .handleError((error) {
          print('Error getting pending workflows: $error');
          return <WorkflowModel>[];
        });
  }

  // Get workflow by ID
  Future<WorkflowModel?> getWorkflowById(String workflowId) async {
    final doc = await _firestore.collection('workflows').doc(workflowId).get();
    if (!doc.exists) return null;
    return WorkflowModel.fromMap(doc.data()!);
  }

  // Get workflow statistics (one-time)
  Future<Map<String, int>> getWorkflowStats({String? userId}) async {
    Query query = _firestore.collection('workflows');

    if (userId != null) {
      query = query.where('initiatorId', isEqualTo: userId);
    }

    final snapshot = await query.get();
    final workflows = snapshot.docs
        .map((doc) => WorkflowModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    return {
      'total': workflows.length,
      'pending': workflows.where((w) => w.status == WorkflowStatus.pending).length,
      'inProgress': workflows.where((w) => w.status == WorkflowStatus.inProgress).length,
      'completed': workflows.where((w) => w.status == WorkflowStatus.completed).length,
      'approved': workflows.where((w) => w.status == WorkflowStatus.approved).length,
      'rejected': workflows.where((w) => w.status == WorkflowStatus.rejected).length,
    };
  }

  // Get workflow statistics as stream (real-time updates)
  Stream<Map<String, int>> getWorkflowStatsStream({String? userId}) {
    // Note: We get all workflows and filter client-side to avoid complex queries
    return _firestore.collection('workflows').snapshots().map((snapshot) {
      try {
        var workflows = snapshot.docs
            .map((doc) {
              try {
                return WorkflowModel.fromMap(doc.data());
              } catch (e) {
                print('Error parsing workflow ${doc.id}: $e');
                return null;
              }
            })
            .where((w) => w != null)
            .cast<WorkflowModel>()
            .toList();

        // Filter by userId if provided (client-side filter for flexibility)
        if (userId != null && userId.isNotEmpty) {
          workflows = workflows.where((w) => w.initiatorId == userId).toList();
        }

        return {
          'total': workflows.length,
          'pending': workflows.where((w) => w.status == WorkflowStatus.pending).length,
          'inProgress': workflows.where((w) => w.status == WorkflowStatus.inProgress).length,
          'completed': workflows.where((w) => w.status == WorkflowStatus.completed).length,
          'approved': workflows.where((w) => w.status == WorkflowStatus.approved).length,
          'rejected': workflows.where((w) => w.status == WorkflowStatus.rejected).length,
        };
      } catch (e) {
        print('Error in workflow stats stream map: $e');
        return <String, int>{
          'total': 0,
          'pending': 0,
          'inProgress': 0,
          'completed': 0,
          'approved': 0,
          'rejected': 0,
        };
      }
    });
  }

  // Private method to notify about workflow status changes
  Future<void> _notifyWorkflowStatusChange(
    WorkflowModel workflow,
    WorkflowStatus status,
    String? notes
  ) async {
    String title = 'Workflow Status Updated';
    String body = 'Workflow "${workflow.title}" status changed to ${status.toString().split('.').last}';

    if (notes != null && notes.isNotEmpty) {
      body += ': $notes';
    }

    // Notify initiator
    try {
      await _notificationService.sendNotificationToUser(
        userId: workflow.initiatorId,
        title: title,
        body: body,
        type: NotificationType.workflow,
        data: {
          'workflowId': workflow.id,
          'status': status.toString(),
          'type': 'workflow_status_changed',
        },
      );
    } catch (e) {
      print('Failed to send workflow status notification: $e');
    }
  }

  // Create predefined workflow templates
  List<WorkflowStepModel> getDocumentRequestWorkflowSteps() {
    return [
      WorkflowStepModel(
        id: _uuid.v4(),
        title: 'Review Request',
        description: 'Review document access request and user credentials',
      ),
      WorkflowStepModel(
        id: _uuid.v4(),
        title: 'Security Check',
        description: 'Verify user security clearance and need-to-know',
      ),
      WorkflowStepModel(
        id: _uuid.v4(),
        title: 'Final Approval',
        description: 'Approve or deny document access',
      ),
    ];
  }

  List<WorkflowStepModel> getMeetingRequestWorkflowSteps() {
    return [
      WorkflowStepModel(
        id: _uuid.v4(),
        title: 'Resource Check',
        description: 'Check room and resource availability',
      ),
      WorkflowStepModel(
        id: _uuid.v4(),
        title: 'Approval',
        description: 'Approve meeting request',
      ),
      WorkflowStepModel(
        id: _uuid.v4(),
        title: 'Setup',
        description: 'Set up meeting room and equipment',
      ),
    ];
  }
}