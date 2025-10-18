import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final double fileSize;
  final String uploadedById;
  final String uploadedByName;
  final List<String> allowedRoles;
  final List<String> allowedDepartments;
  final DocumentCategory category;
  final DateTime createdAt;
  final DateTime? lastModified;
  final bool isActive;

  DocumentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedById,
    required this.uploadedByName,
    required this.allowedRoles,
    required this.allowedDepartments,
    required this.category,
    required this.createdAt,
    this.lastModified,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedById': uploadedById,
      'uploadedByName': uploadedByName,
      'allowedRoles': allowedRoles,
      'allowedDepartments': allowedDepartments,
      'category': category.toString(),
      'createdAt': createdAt,
      'lastModified': lastModified,
      'isActive': isActive,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? '',
      fileSize: map['fileSize']?.toDouble() ?? 0.0,
      uploadedById: map['uploadedById'] ?? '',
      uploadedByName: map['uploadedByName'] ?? '',
      allowedRoles: List<String>.from(map['allowedRoles'] ?? []),
      allowedDepartments: List<String>.from(map['allowedDepartments'] ?? []),
      category: DocumentCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => DocumentCategory.general,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastModified: map['lastModified'] != null
          ? (map['lastModified'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
    );
  }
}

class DocumentRequestModel {
  final String id;
  final String documentId;
  final String documentTitle;
  final String requesterId;
  final String requesterName;
  final String reason;
  final RequestStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final String? approvedById;
  final String? approvedByName;
  final String? rejectionReason;

  DocumentRequestModel({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.requesterId,
    required this.requesterName,
    required this.reason,
    this.status = RequestStatus.pending,
    required this.requestedAt,
    this.approvedAt,
    this.approvedById,
    this.approvedByName,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'documentTitle': documentTitle,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'reason': reason,
      'status': status.toString(),
      'requestedAt': requestedAt,
      'approvedAt': approvedAt,
      'approvedById': approvedById,
      'approvedByName': approvedByName,
      'rejectionReason': rejectionReason,
    };
  }

  factory DocumentRequestModel.fromMap(Map<String, dynamic> map) {
    return DocumentRequestModel(
      id: map['id'] ?? '',
      documentId: map['documentId'] ?? '',
      documentTitle: map['documentTitle'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      reason: map['reason'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      approvedById: map['approvedById'],
      approvedByName: map['approvedByName'],
      rejectionReason: map['rejectionReason'],
    );
  }
}

enum DocumentCategory {
  reports,
  policies,
  procedures,
  forms,
  general,
}

enum RequestStatus {
  pending,
  approved,
  rejected,
}