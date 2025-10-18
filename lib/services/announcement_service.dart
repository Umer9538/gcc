import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/announcement_model.dart';
import 'notification_service.dart';
import 'user_service.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();

  Stream<List<AnnouncementModel>> getAnnouncementsForUser({
    required String userId,
    required String userDepartment,
    required List<String> userRoles,
  }) {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📢 Total announcements from DB: ${snapshot.docs.length}');

      final filtered = snapshot.docs
          .map((doc) => AnnouncementModel.fromMap(doc.data()))
          .where((announcement) {
        print('📋 Checking announcement: ${announcement.title}');
        print('   - targetGroups: ${announcement.targetGroups}');
        print('   - targetDepartments: ${announcement.targetDepartments}');
        print('   - userDepartment: $userDepartment');
        print('   - userRoles: $userRoles');

        // Show announcement if:
        // 1. No targeting (show to everyone)
        if (announcement.targetGroups.isEmpty && announcement.targetDepartments.isEmpty) {
          print('   ✅ SHOW - No targeting');
          return true;
        }

        // 2. Explicitly targeted to 'all'
        if (announcement.targetGroups.contains('all')) {
          print('   ✅ SHOW - Contains "all"');
          return true;
        }

        // 3. User's department matches
        if (userDepartment.isNotEmpty &&
            announcement.targetDepartments.isNotEmpty &&
            announcement.targetDepartments.contains(userDepartment)) {
          print('   ✅ SHOW - Department match');
          return true;
        }

        // 4. User's role matches
        if (userRoles.isNotEmpty && announcement.targetGroups.isNotEmpty) {
          for (var role in userRoles) {
            if (announcement.targetGroups.contains(role)) {
              print('   ✅ SHOW - Role match: $role');
              return true;
            }
          }
        }

        print('   ❌ HIDE - No match');
        return false;
      }).toList();

      print('📊 Filtered announcements: ${filtered.length}');
      return filtered;
    });
  }

  Future<String> createAnnouncement({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    required List<String> targetGroups,
    required List<String> targetDepartments,
    AnnouncementPriority priority = AnnouncementPriority.normal,
    DateTime? expiryDate,
  }) async {
    final String announcementId = _uuid.v4();

    final announcement = AnnouncementModel(
      id: announcementId,
      title: title,
      content: content,
      authorId: authorId,
      authorName: authorName,
      targetGroups: targetGroups,
      targetDepartments: targetDepartments,
      priority: priority,
      createdAt: DateTime.now(),
      expiryDate: expiryDate,
    );

    await _firestore
        .collection('announcements')
        .doc(announcementId)
        .set(announcement.toMap());

    // Send notifications to target users
    try {
      final targetUserIds = await _getTargetUserIds(targetGroups, targetDepartments);
      if (targetUserIds.isNotEmpty) {
        await _notificationService.sendAnnouncementNotification(
          announcementId: announcementId,
          title: title,
          content: content,
          targetUserIds: targetUserIds,
        );
      }
    } catch (e) {
      print('Failed to send announcement notifications: $e');
    }

    return announcementId;
  }

  Future<void> markAnnouncementAsRead(String announcementId, String userId) async {
    await _firestore.collection('announcements').doc(announcementId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> updateAnnouncement(String announcementId, Map<String, dynamic> updates) async {
    await _firestore.collection('announcements').doc(announcementId).update(updates);
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore.collection('announcements').doc(announcementId).update({
      'isActive': false,
    });
  }

  Future<AnnouncementModel?> getAnnouncementById(String announcementId) async {
    final doc = await _firestore.collection('announcements').doc(announcementId).get();
    if (!doc.exists) return null;
    return AnnouncementModel.fromMap(doc.data()!);
  }

  Stream<List<AnnouncementModel>> getAllAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromMap(doc.data()))
            .toList());
  }

  Future<List<AnnouncementModel>> getUnreadAnnouncements(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .where('readBy', whereNotIn: [userId])
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AnnouncementModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadAnnouncementCount({
    required String userId,
    required String userDepartment,
    required List<String> userRoles,
  }) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .get();

    int unreadCount = 0;
    for (var doc in snapshot.docs) {
      final announcement = AnnouncementModel.fromMap(doc.data() as Map<String, dynamic>);

      bool isTargeted = announcement.targetGroups.isEmpty ||
          announcement.targetGroups.contains('all') ||
          announcement.targetDepartments.contains(userDepartment) ||
          userRoles.any((role) => announcement.targetGroups.contains(role));

      bool isRead = announcement.readBy.contains(userId);

      if (isTargeted && !isRead) {
        unreadCount++;
      }
    }

    return unreadCount;
  }

  Future<List<String>> _getTargetUserIds(List<String> targetGroups, List<String> targetDepartments) async {
    Set<String> userIds = {};

    if (targetGroups.contains('all') || (targetGroups.isEmpty && targetDepartments.isEmpty)) {
      final allUsers = await _userService.getAllUsers().first;
      userIds.addAll(allUsers.map((user) => user.id));
      return userIds.toList();
    }

    for (String department in targetDepartments) {
      final departmentUsers = await _userService.getUsersByDepartment(department).first;
      userIds.addAll(departmentUsers.map((user) => user.id));
    }

    for (String role in targetGroups) {
      if (role != 'all') {
        final roleUsers = await _userService.getUsersByRole(role);
        userIds.addAll(roleUsers.map((user) => user.id));
      }
    }

    return userIds.toList();
  }
}