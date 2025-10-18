import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();

  Stream<List<DocumentModel>> getDocumentsForUser({
    required String userId,
    required String userDepartment,
    required List<String> userRoles,
  }) {
    return _firestore
        .collection('documents')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DocumentModel.fromMap(doc.data()))
          .where((document) {
        return document.allowedRoles.isEmpty ||
            document.allowedRoles.any((role) => userRoles.contains(role)) ||
            document.allowedDepartments.contains(userDepartment);
      }).toList();
    });
  }

  Stream<List<DocumentModel>> getDocumentsByCategory(DocumentCategory category) {
    return _firestore
        .collection('documents')
        .where('category', isEqualTo: category.toString())
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentModel.fromMap(doc.data()))
            .toList());
  }

  Future<String> uploadDocument({
    required String title,
    required String description,
    required String filePath,
    required String fileName,
    required String fileType,
    required double fileSize,
    required String uploadedById,
    required String uploadedByName,
    required List<String> allowedRoles,
    required List<String> allowedDepartments,
    required DocumentCategory category,
  }) async {
    final String documentId = _uuid.v4();
    final String storagePath = 'documents/$documentId/$fileName';

    final Reference ref = _storage.ref().child(storagePath);

    final String downloadUrl = await ref.getDownloadURL();

    final document = DocumentModel(
      id: documentId,
      title: title,
      description: description,
      fileUrl: downloadUrl,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      uploadedById: uploadedById,
      uploadedByName: uploadedByName,
      allowedRoles: allowedRoles,
      allowedDepartments: allowedDepartments,
      category: category,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('documents')
        .doc(documentId)
        .set(document.toMap());

    return documentId;
  }

  Future<String> requestDocumentAccess({
    required String documentId,
    required String documentTitle,
    required String requesterId,
    required String requesterName,
    required String reason,
  }) async {
    final String requestId = _uuid.v4();

    final request = DocumentRequestModel(
      id: requestId,
      documentId: documentId,
      documentTitle: documentTitle,
      requesterId: requesterId,
      requesterName: requesterName,
      reason: reason,
      requestedAt: DateTime.now(),
    );

    await _firestore
        .collection('document_requests')
        .doc(requestId)
        .set(request.toMap());

    // Notify document owner about the request
    try {
      final document = await getDocumentById(documentId);
      if (document != null) {
        await _notificationService.sendNotificationToUser(
          userId: document.uploadedById,
          title: 'Document Access Request',
          body: '$requesterName has requested access to "${document.title}"',
          type: NotificationType.document,
          data: {
            'requestId': requestId,
            'documentId': documentId,
            'type': 'document_request',
          },
        );
      }
    } catch (e) {
      print('Failed to send document request notification: $e');
    }

    return requestId;
  }

  Stream<List<DocumentRequestModel>> getDocumentRequests() {
    return _firestore
        .collection('document_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentRequestModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<DocumentRequestModel>> getUserDocumentRequests(String userId) {
    return _firestore
        .collection('document_requests')
        .where('requesterId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentRequestModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> approveDocumentRequest({
    required String requestId,
    required String approvedById,
    required String approvedByName,
  }) async {
    final request = await getDocumentRequestById(requestId);
    if (request == null) return;

    await _firestore.collection('document_requests').doc(requestId).update({
      'status': RequestStatus.approved.toString(),
      'approvedAt': DateTime.now(),
      'approvedById': approvedById,
      'approvedByName': approvedByName,
    });

    // Grant access to the document
    await _grantDocumentAccess(request.documentId, request.requesterId);

    // Notify requester about approval
    try {
      await _notificationService.sendNotificationToUser(
        userId: request.requesterId,
        title: 'Document Access Approved',
        body: 'Your request for "${request.documentTitle}" has been approved',
        type: NotificationType.document,
        data: {
          'requestId': requestId,
          'documentId': request.documentId,
          'isApproved': true,
          'type': 'document_response',
        },
      );
    } catch (e) {
      print('Failed to send document approval notification: $e');
    }
  }

  Future<void> rejectDocumentRequest({
    required String requestId,
    required String rejectionReason,
    required String approvedById,
    required String approvedByName,
  }) async {
    final request = await getDocumentRequestById(requestId);
    if (request == null) return;

    await _firestore.collection('document_requests').doc(requestId).update({
      'status': RequestStatus.rejected.toString(),
      'approvedAt': DateTime.now(),
      'approvedById': approvedById,
      'approvedByName': approvedByName,
      'rejectionReason': rejectionReason,
    });

    // Notify requester about rejection
    try {
      await _notificationService.sendNotificationToUser(
        userId: request.requesterId,
        title: 'Document Access Denied',
        body: 'Your request for "${request.documentTitle}" has been denied: $rejectionReason',
        type: NotificationType.document,
        data: {
          'requestId': requestId,
          'documentId': request.documentId,
          'isApproved': false,
          'rejectionReason': rejectionReason,
          'type': 'document_response',
        },
      );
    } catch (e) {
      print('Failed to send document rejection notification: $e');
    }
  }

  Future<DocumentModel?> getDocumentById(String documentId) async {
    final doc = await _firestore.collection('documents').doc(documentId).get();
    if (!doc.exists) return null;
    return DocumentModel.fromMap(doc.data()!);
  }

  Future<void> updateDocument(String documentId, Map<String, dynamic> updates) async {
    updates['lastModified'] = DateTime.now();
    await _firestore.collection('documents').doc(documentId).update(updates);
  }

  Future<void> deleteDocument(String documentId) async {
    await _firestore.collection('documents').doc(documentId).update({
      'isActive': false,
    });

    try {
      final doc = await getDocumentById(documentId);
      if (doc != null && doc.fileUrl.isNotEmpty) {
        final ref = _storage.refFromURL(doc.fileUrl);
        await ref.delete();
      }
    } catch (e) {
      print('Error deleting file from storage: $e');
    }
  }

  Future<List<DocumentModel>> searchDocuments(String query) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('documents')
        .where('isActive', isEqualTo: true)
        .get();

    final List<DocumentModel> documents = snapshot.docs
        .map((doc) => DocumentModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    return documents.where((document) {
      final String searchQuery = query.toLowerCase();
      return document.title.toLowerCase().contains(searchQuery) ||
          document.description.toLowerCase().contains(searchQuery) ||
          document.fileName.toLowerCase().contains(searchQuery);
    }).toList();
  }

  Future<DocumentRequestModel?> getDocumentRequestById(String requestId) async {
    final doc = await _firestore.collection('document_requests').doc(requestId).get();
    if (!doc.exists) return null;
    return DocumentRequestModel.fromMap(doc.data()!);
  }

  Future<void> _grantDocumentAccess(String documentId, String userId) async {
    await _firestore.collection('document_access').add({
      'documentId': documentId,
      'userId': userId,
      'grantedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<DocumentRequestModel>> getPendingRequestsForUser(String userId) {
    return _firestore
        .collection('document_requests')
        .where('status', isEqualTo: RequestStatus.pending.toString())
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<DocumentRequestModel> relevantRequests = [];

      for (var doc in snapshot.docs) {
        final request = DocumentRequestModel.fromMap(doc.data());
        final document = await getDocumentById(request.documentId);

        if (document?.uploadedById == userId) {
          relevantRequests.add(request);
        }
      }

      return relevantRequests;
    });
  }

  Future<Map<String, int>> getDocumentStats({
    required String userId,
    required String userDepartment,
    required List<String> userRoles,
  }) async {
    final accessible = await getDocumentsForUser(
      userId: userId,
      userDepartment: userDepartment,
      userRoles: userRoles,
    ).first;

    final userRequests = await getUserDocumentRequests(userId).first;
    final pendingRequests = await getPendingRequestsForUser(userId).first;

    return {
      'accessibleDocuments': accessible.length,
      'pendingRequests': userRequests.where((r) => r.status == RequestStatus.pending).length,
      'approvedRequests': userRequests.where((r) => r.status == RequestStatus.approved).length,
      'rejectedRequests': userRequests.where((r) => r.status == RequestStatus.rejected).length,
      'requestsToReview': pendingRequests.length,
    };
  }
}