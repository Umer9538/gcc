import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../constants/app_constants.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final isRTL = appProvider.isRTL;

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isRTL ? 'الإشعارات' : 'Notifications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Text(isRTL ? 'الكل' : 'All'),
              ),
              PopupMenuItem(
                value: 'unread',
                child: Text(isRTL ? 'غير مقروء' : 'Unread'),
              ),
              PopupMenuItem(
                value: 'read',
                child: Text(isRTL ? 'مقروء' : 'Read'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: isRTL ? 'تحديد الكل كمقروء' : 'Mark all as read',
            onPressed: () async {
              await _notificationService
                  .markAllNotificationsAsRead(authProvider.currentUser!.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isRTL
                          ? 'تم تحديد جميع الإشعارات كمقروءة'
                          : 'All notifications marked as read',
                    ),
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isRTL ? 'الكل' : 'All'),
            Tab(text: isRTL ? 'الاجتماعات' : 'Meetings'),
            Tab(text: isRTL ? 'الرسائل' : 'Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(authProvider.currentUser!.id, null, isRTL),
          _buildNotificationsList(
              authProvider.currentUser!.id, NotificationType.meeting, isRTL),
          _buildNotificationsList(
              authProvider.currentUser!.id, NotificationType.message, isRTL),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
      String userId, NotificationType? type, bool isRTL) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getUserNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              isRTL ? 'حدث خطأ في تحميل الإشعارات' : 'Error loading notifications',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.errorColor,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: AppColors.textLightColor,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  isRTL ? 'لا توجد إشعارات' : 'No notifications',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        var notifications = snapshot.data!;

        // Filter by type
        if (type != null) {
          notifications =
              notifications.where((n) => n.type == type).toList();
        }

        // Filter by read status
        if (_selectedFilter == 'unread') {
          notifications = notifications.where((n) => !n.isRead).toList();
        } else if (_selectedFilter == 'read') {
          notifications = notifications.where((n) => n.isRead).toList();
        }

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: AppColors.textLightColor,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  isRTL ? 'لا توجد إشعارات' : 'No notifications',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: notifications.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppConstants.smallPadding),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification, isRTL);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, bool isRTL) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: AppColors.errorColor,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await _notificationService.deleteNotification(notification.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRTL ? 'تم حذف الإشعار' : 'Notification deleted',
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead
            ? AppColors.surfaceColor
            : AppColors.primaryColor.withValues(alpha: 0.05),
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await _notificationService
                  .markNotificationAsRead(notification.id);
            }
            // Handle navigation based on notification type
            _handleNotificationTap(notification);
          },
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification.type, notification.priority),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        notification.body,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Row(
                        children: [
                          Text(
                            timeago.format(notification.createdAt),
                            style: AppTextStyles.bodySmall,
                          ),
                          if (notification.priority == NotificationPriority.high ||
                              notification.priority == NotificationPriority.urgent)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: AppConstants.smallPadding),
                              child: Icon(
                                Icons.priority_high,
                                size: 16,
                                color: notification.priority ==
                                        NotificationPriority.urgent
                                    ? AppColors.errorColor
                                    : AppColors.warningColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(
      NotificationType type, NotificationPriority priority) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.meeting:
        iconData = Icons.event;
        iconColor = AppColors.primaryColor;
        break;
      case NotificationType.announcement:
        iconData = Icons.campaign;
        iconColor = AppColors.secondaryColor;
        break;
      case NotificationType.message:
        iconData = Icons.message;
        iconColor = AppColors.accentColor;
        break;
      case NotificationType.workflow:
        iconData = Icons.assignment;
        iconColor = AppColors.gentlePurple;
        break;
      case NotificationType.document:
        iconData = Icons.description;
        iconColor = AppColors.gentleOrange;
        break;
      case NotificationType.reminder:
        iconData = Icons.alarm;
        iconColor = AppColors.warningColor;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.textSecondaryColor;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle navigation based on notification type and data
    switch (notification.type) {
      case NotificationType.meeting:
        // Navigate to meeting details
        if (notification.data?['meetingId'] != null) {
          // Navigator.push(...);
        }
        break;
      case NotificationType.announcement:
        // Navigate to announcement details
        if (notification.data?['announcementId'] != null) {
          // Navigator.push(...);
        }
        break;
      case NotificationType.message:
        // Navigate to chat
        if (notification.data?['conversationId'] != null) {
          // Navigator.push(...);
        }
        break;
      case NotificationType.workflow:
        // Navigate to workflow details
        break;
      case NotificationType.document:
        // Navigate to document
        break;
      default:
        break;
    }
  }
}
