import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/app_constants.dart';
import '../../services/workflow_service.dart';
import '../../utils/date_utils.dart';

class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({super.key});

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> with SingleTickerProviderStateMixin {
  final WorkflowService _workflowService = WorkflowService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, app_auth.AuthProvider>(
      builder: (context, appProvider, authProvider, child) {
        final isRTL = appProvider.isRTL;
        final currentUser = authProvider.currentUser;
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(
              isRTL ? 'تتبع سير العمل' : 'Workflow Tracking',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: [
                Tab(text: isRTL ? 'طلباتي' : 'My Workflows'),
                Tab(text: isRTL ? 'المُكلف بها' : 'Assigned'),
                Tab(text: isRTL ? 'المعلقة' : 'Pending'),
                Tab(text: isRTL ? 'الإحصائيات' : 'Statistics'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMyWorkflowsTab(userId, isRTL),
              _buildAssignedWorkflowsTab(userId, isRTL),
              _buildPendingWorkflowsTab(isRTL),
              _buildStatisticsTab(userId, isRTL),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateWorkflowDialog(context, currentUser, isRTL),
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildMyWorkflowsTab(String userId, bool isRTL) {
    return StreamBuilder<List<WorkflowModel>>(
      stream: _workflowService.getWorkflowsForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            isRTL ? 'لا توجد طلبات سير عمل' : 'No workflows',
            isRTL ? 'لم تقم بإنشاء أي طلبات سير عمل بعد' : 'You haven\'t created any workflows yet',
            Icons.work_outline,
          );
        }

        final workflows = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: workflows.length,
          itemBuilder: (context, index) {
            final workflow = workflows[index];
            return _buildWorkflowCard(workflow, isRTL, true);
          },
        );
      },
    );
  }

  Widget _buildAssignedWorkflowsTab(String userId, bool isRTL) {
    return StreamBuilder<List<WorkflowModel>>(
      stream: _workflowService.getAssignedWorkflows(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            isRTL ? 'لا توجد مهام مُكلف بها' : 'No assigned workflows',
            isRTL ? 'لا توجد مهام سير عمل مُكلف بها حالياً' : 'No workflows currently assigned to you',
            Icons.assignment_outlined,
          );
        }

        final workflows = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: workflows.length,
          itemBuilder: (context, index) {
            final workflow = workflows[index];
            return _buildWorkflowCard(workflow, isRTL, false);
          },
        );
      },
    );
  }

  Widget _buildPendingWorkflowsTab(bool isRTL) {
    return StreamBuilder<List<WorkflowModel>>(
      stream: _workflowService.getPendingWorkflows(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            isRTL ? 'لا توجد طلبات معلقة' : 'No pending workflows',
            isRTL ? 'لا توجد طلبات سير عمل معلقة للمراجعة' : 'No pending workflows to review',
            Icons.pending_actions_outlined,
          );
        }

        final workflows = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: workflows.length,
          itemBuilder: (context, index) {
            final workflow = workflows[index];
            return _buildWorkflowCard(workflow, isRTL, false, showActions: true);
          },
        );
      },
    );
  }

  Widget _buildStatisticsTab(String userId, bool isRTL) {
    return FutureBuilder<Map<String, int>>(
      future: _workflowService.getWorkflowStats(userId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(
            isRTL ? 'خطأ في تحميل الإحصائيات' : 'Error loading statistics',
            isRTL ? 'حاول مرة أخرى لاحقاً' : 'Please try again later',
            Icons.error_outline,
          );
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              _buildStatCard(
                isRTL ? 'إجمالي طلبات سير العمل' : 'Total Workflows',
                stats['total'] ?? 0,
                Icons.work,
                AppColors.primaryColor,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildStatCard(
                isRTL ? 'الطلبات المعلقة' : 'Pending Workflows',
                stats['pending'] ?? 0,
                Icons.pending,
                AppColors.warningColor,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildStatCard(
                isRTL ? 'قيد التنفيذ' : 'In Progress',
                stats['inProgress'] ?? 0,
                Icons.work_history,
                AppColors.infoColor,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildStatCard(
                isRTL ? 'المكتملة' : 'Completed',
                stats['completed'] ?? 0,
                Icons.check_circle,
                AppColors.successColor,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      isRTL ? 'المقبولة' : 'Approved',
                      stats['approved'] ?? 0,
                      Icons.thumb_up,
                      AppColors.gentleGreen,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: _buildStatCard(
                      isRTL ? 'المرفوضة' : 'Rejected',
                      stats['rejected'] ?? 0,
                      Icons.thumb_down,
                      AppColors.errorColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkflowCard(WorkflowModel workflow, bool isRTL, bool isOwner, {bool showActions = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: InkWell(
        onTap: () => _showWorkflowDetails(workflow, isRTL),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and type
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(workflow.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getWorkflowTypeIcon(workflow.type),
                      color: _getStatusColor(workflow.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workflow.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getWorkflowTypeText(workflow.type, isRTL),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(workflow.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(workflow.status, isRTL),
                      style: TextStyle(
                        color: _getStatusColor(workflow.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Description
              Text(
                workflow.description,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Progress indicator for multi-step workflows
              if (workflow.steps.isNotEmpty) ...[
                _buildProgressIndicator(workflow, isRTL),
                const SizedBox(height: AppConstants.defaultPadding),
              ],

              // Workflow info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwner
                            ? (isRTL ? 'بواسطتك' : 'By you')
                            : '${isRTL ? 'بواسطة' : 'By'}: ${workflow.initiatorName}',
                        style: AppTextStyles.bodySmall,
                      ),
                      if (workflow.assigneeName != null)
                        Text(
                          '${isRTL ? 'مُكلف إلى' : 'Assigned to'}: ${workflow.assigneeName}',
                          style: AppTextStyles.bodySmall,
                        ),
                    ],
                  ),
                  Text(
                    AppDateUtils.formatDate(workflow.createdAt, locale: isRTL ? 'ar' : 'en'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ),

              // Action buttons for pending workflows
              if (showActions && workflow.status == WorkflowStatus.pending) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _updateWorkflowStatus(workflow.id, WorkflowStatus.rejected, isRTL),
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(isRTL ? 'رفض' : 'Reject'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.errorColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _updateWorkflowStatus(workflow.id, WorkflowStatus.approved, isRTL),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(isRTL ? 'قبول' : 'Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(WorkflowModel workflow, bool isRTL) {
    final totalSteps = workflow.steps.length;
    final completedSteps = workflow.steps.where((step) => step.status == WorkflowStatus.completed).length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isRTL ? 'التقدم' : 'Progress',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$completedSteps/$totalSteps ${isRTL ? 'خطوات' : 'steps'}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.borderColor,
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(workflow.status)),
        ),
        const SizedBox(height: 8),
        if (workflow.currentStepIndex < workflow.steps.length) ...[
          Text(
            '${isRTL ? 'الخطوة الحالية' : 'Current step'}: ${workflow.steps[workflow.currentStepIndex].title}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toString(),
                    style: AppTextStyles.heading3.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textLightColor,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getWorkflowTypeIcon(WorkflowType type) {
    switch (type) {
      case WorkflowType.documentRequest:
        return Icons.description;
      case WorkflowType.meetingRequest:
        return Icons.event;
      case WorkflowType.announcementApproval:
        return Icons.announcement;
      case WorkflowType.userRegistration:
        return Icons.person_add;
      case WorkflowType.roleChange:
        return Icons.admin_panel_settings;
    }
  }

  String _getWorkflowTypeText(WorkflowType type, bool isRTL) {
    switch (type) {
      case WorkflowType.documentRequest:
        return isRTL ? 'طلب وثيقة' : 'Document Request';
      case WorkflowType.meetingRequest:
        return isRTL ? 'طلب اجتماع' : 'Meeting Request';
      case WorkflowType.announcementApproval:
        return isRTL ? 'موافقة إعلان' : 'Announcement Approval';
      case WorkflowType.userRegistration:
        return isRTL ? 'تسجيل مستخدم' : 'User Registration';
      case WorkflowType.roleChange:
        return isRTL ? 'تغيير الدور' : 'Role Change';
    }
  }

  Color _getStatusColor(WorkflowStatus status) {
    switch (status) {
      case WorkflowStatus.pending:
        return AppColors.warningColor;
      case WorkflowStatus.inProgress:
        return AppColors.infoColor;
      case WorkflowStatus.approved:
        return AppColors.successColor;
      case WorkflowStatus.rejected:
        return AppColors.errorColor;
      case WorkflowStatus.completed:
        return AppColors.gentleGreen;
      case WorkflowStatus.cancelled:
        return AppColors.textSecondaryColor;
    }
  }

  String _getStatusText(WorkflowStatus status, bool isRTL) {
    switch (status) {
      case WorkflowStatus.pending:
        return isRTL ? 'معلق' : 'Pending';
      case WorkflowStatus.inProgress:
        return isRTL ? 'قيد التنفيذ' : 'In Progress';
      case WorkflowStatus.approved:
        return isRTL ? 'مقبول' : 'Approved';
      case WorkflowStatus.rejected:
        return isRTL ? 'مرفوض' : 'Rejected';
      case WorkflowStatus.completed:
        return isRTL ? 'مكتمل' : 'Completed';
      case WorkflowStatus.cancelled:
        return isRTL ? 'ملغي' : 'Cancelled';
    }
  }

  void _showWorkflowDetails(WorkflowModel workflow, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workflow.title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${isRTL ? 'النوع' : 'Type'}: ${_getWorkflowTypeText(workflow.type, isRTL)}',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${isRTL ? 'الحالة' : 'Status'}: ${_getStatusText(workflow.status, isRTL)}',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${isRTL ? 'الوصف' : 'Description'}:',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(workflow.description),
              const SizedBox(height: 16),
              if (workflow.steps.isNotEmpty) ...[
                Text(
                  isRTL ? 'خطوات سير العمل:' : 'Workflow Steps:',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...workflow.steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isCurrentStep = index == workflow.currentStepIndex;
                  final isCompleted = step.status == WorkflowStatus.completed;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.successColor
                                : isCurrentStep
                                    ? AppColors.infoColor
                                    : AppColors.borderColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check : Icons.circle,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
                              color: isCurrentStep ? AppColors.primaryColor : AppColors.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              const SizedBox(height: 16),
              Text(
                '${isRTL ? 'تاريخ الإنشاء' : 'Created'}: ${AppDateUtils.formatDate(workflow.createdAt, locale: isRTL ? 'ar' : 'en')}',
                style: AppTextStyles.bodySmall,
              ),
              if (workflow.completedAt != null)
                Text(
                  '${isRTL ? 'تاريخ الإكمال' : 'Completed'}: ${AppDateUtils.formatDate(workflow.completedAt!, locale: isRTL ? 'ar' : 'en')}',
                  style: AppTextStyles.bodySmall,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateWorkflowDialog(BuildContext context, currentUser, bool isRTL) {
    if (currentUser == null) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    WorkflowType selectedType = WorkflowType.documentRequest;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isRTL ? 'إنشاء طلب سير عمل جديد' : 'Create New Workflow'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<WorkflowType>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'نوع سير العمل' : 'Workflow Type',
                    border: const OutlineInputBorder(),
                  ),
                  items: WorkflowType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getWorkflowTypeText(type, isRTL)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'العنوان' : 'Title',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'الوصف' : 'Description',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isRTL ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty &&
                    descriptionController.text.trim().isNotEmpty) {

                  List<WorkflowStepModel> steps = [];
                  if (selectedType == WorkflowType.documentRequest) {
                    steps = _workflowService.getDocumentRequestWorkflowSteps();
                  } else if (selectedType == WorkflowType.meetingRequest) {
                    steps = _workflowService.getMeetingRequestWorkflowSteps();
                  }

                  await _workflowService.createWorkflow(
                    type: selectedType,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    initiatorId: currentUser.id,
                    initiatorName: currentUser.fullName,
                    steps: steps,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isRTL ? 'تم إنشاء طلب سير العمل' : 'Workflow created successfully'),
                        backgroundColor: AppColors.successColor,
                      ),
                    );
                  }
                }
              },
              child: Text(isRTL ? 'إنشاء' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateWorkflowStatus(String workflowId, WorkflowStatus status, bool isRTL) async {
    await _workflowService.updateWorkflowStatus(
      workflowId: workflowId,
      status: status,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == WorkflowStatus.approved
                ? (isRTL ? 'تم قبول طلب سير العمل' : 'Workflow approved')
                : (isRTL ? 'تم رفض طلب سير العمل' : 'Workflow rejected'),
          ),
          backgroundColor: status == WorkflowStatus.approved ? AppColors.successColor : AppColors.errorColor,
        ),
      );
    }
  }
}