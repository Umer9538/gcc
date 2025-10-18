import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final List<String> targetGroups;
  final List<String> targetDepartments;
  final AnnouncementPriority priority;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final bool isActive;
  final List<String> readBy;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.targetGroups,
    required this.targetDepartments,
    this.priority = AnnouncementPriority.normal,
    required this.createdAt,
    this.expiryDate,
    this.isActive = true,
    this.readBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'targetGroups': targetGroups,
      'targetDepartments': targetDepartments,
      'priority': priority.toString(),
      'createdAt': createdAt,
      'expiryDate': expiryDate,
      'isActive': isActive,
      'readBy': readBy,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      targetGroups: List<String>.from(map['targetGroups'] ?? []),
      targetDepartments: List<String>.from(map['targetDepartments'] ?? []),
      priority: AnnouncementPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => AnnouncementPriority.normal,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiryDate: map['expiryDate'] != null
          ? (map['expiryDate'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}

enum AnnouncementPriority {
  low,
  normal,
  high,
  urgent,
}