import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../constants/app_constants.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get the FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Save FCM token for user
  Future<void> saveTokenForUser(String userId) async {
    String? token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    NotificationType? type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  }) async {
    final docRef = _firestore.collection('notifications').doc();

    final notification = NotificationModel(
      id: docRef.id,
      userId: userId,
      title: title,
      body: body,
      type: type ?? NotificationType.general,
      priority: priority,
      data: data,
      createdAt: DateTime.now(),
      actionUrl: actionUrl,
      imageUrl: imageUrl,
    );

    await docRef.set(notification.toJson());

    // Get user's FCM token and send push notification
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken != null && kDebugMode) {
        print('Sending notification to token: $fcmToken');
      }
    }
  }

  // Send notification to multiple users
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    NotificationType? type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  }) async {
    final batch = _firestore.batch();

    for (String userId in userIds) {
      final docRef = _firestore.collection('notifications').doc();

      final notification = NotificationModel(
        id: docRef.id,
        userId: userId,
        title: title,
        body: body,
        type: type ?? NotificationType.general,
        priority: priority,
        data: data,
        createdAt: DateTime.now(),
        actionUrl: actionUrl,
        imageUrl: imageUrl,
      );

      batch.set(docRef, notification.toJson());
    }

    await batch.commit();
  }

  // Send announcement notification
  Future<void> sendAnnouncementNotification({
    required String announcementId,
    required String title,
    required String content,
    required List<String> targetUserIds,
  }) async {
    await sendNotificationToUsers(
      userIds: targetUserIds,
      title: 'New Announcement: $title',
      body: content.length > 100 ? '${content.substring(0, 100)}...' : content,
      type: NotificationType.announcement,
      data: {
        'announcementId': announcementId,
      },
    );
  }

  // Send meeting notification
  Future<void> sendMeetingNotification({
    required String meetingId,
    required String title,
    required List<String> attendeeIds,
    required String notifType, // 'created', 'updated', 'reminder', 'cancelled'
    DateTime? meetingTime,
  }) async {
    String body;
    switch (notifType) {
      case 'created':
        body = 'You have been invited to a new meeting: $title';
        break;
      case 'updated':
        body = 'Meeting "$title" has been updated';
        break;
      case 'reminder':
        body = 'Meeting "$title" starts in 15 minutes';
        break;
      case 'cancelled':
        body = 'Meeting "$title" has been cancelled';
        break;
      default:
        body = 'Meeting notification: $title';
    }

    await sendNotificationToUsers(
      userIds: attendeeIds,
      title: 'Meeting Notification',
      body: body,
      type: NotificationType.meeting,
      data: {
        'meetingId': meetingId,
        'notifType': notifType,
        'meetingTime': meetingTime?.toIso8601String(),
      },
    );
  }

  // Send message notification
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: 'New message from $senderName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      type: NotificationType.message,
      data: {
        'conversationId': conversationId,
        'senderId': receiverId,
      },
    );
  }

  // Get user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList());
  }

  // Get unread notification count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark all notifications as read for user
  Future<void> markAllNotificationsAsRead(String userId) async {
    final query = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    final query = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return query.docs.length;
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    // Handle the message (show in-app notification, update UI, etc.)
  }

  // Handle when user taps on notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message clicked: ${message.data}');
    // Navigate to appropriate screen based on notification data
    final type = message.data['type'];
    switch (type) {
      case 'announcement':
        // Navigate to announcements screen
        break;
      case 'meeting':
        // Navigate to meetings screen
        break;
      case 'message':
        // Navigate to chat screen
        break;
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
}

// In-app notification widget
class InAppNotification extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotification({
    super.key,
    required this.title,
    required this.body,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: ListTile(
        leading: const Icon(
          Icons.notifications_active,
          color: AppColors.primaryColor,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(body, style: AppTextStyles.bodyMedium),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onDismiss,
        ),
        onTap: onTap,
      ),
    );
  }
}