import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/date_utils.dart';
import '../../services/meeting_service.dart';
import '../../services/announcement_service.dart';
import '../../models/meeting_model.dart';
import '../../models/announcement_model.dart';
import '../meetings/meetings_screen.dart';
import '../announcements/announcements_screen.dart';
import '../directory/directory_screen.dart';
import '../documents/documents_screen.dart';
import '../workflow/workflow_screen.dart';
import '../messaging/messaging_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MeetingService _meetingService = MeetingService();
  final AnnouncementService _announcementService = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    return Consumer2<app_auth.AuthProvider, AppProvider>(
      builder: (context, authProvider, appProvider, child) {
        final user = authProvider.currentUser;
        final isRTL = appProvider.isRTL;
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(
              isRTL ? 'لوحة التحكم' : 'Dashboard',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Navigate to notifications
                },
              ),
              IconButton(
                icon: const Icon(Icons.search_outlined),
                onPressed: () {
                  // TODO: Open search
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appProvider.getGreeting(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        user?.fullName ?? (isRTL ? 'مستخدم' : 'User'),
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        user?.position ?? (isRTL ? 'المنصب' : 'Position'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        user?.department ?? (isRTL ? 'القسم' : 'Department'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.largePadding),

                // Quick Actions
                Text(
                  isRTL ? 'الإجراءات السريعة' : 'Quick Actions',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate responsive grid
                    final double availableWidth = constraints.maxWidth;
                    final double cardWidth = (availableWidth - AppConstants.defaultPadding) / 2;
                    final double cardHeight = cardWidth * 0.85; // More responsive ratio

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: AppConstants.defaultPadding,
                      mainAxisSpacing: AppConstants.defaultPadding,
                      childAspectRatio: cardWidth / cardHeight,
                      children: [
                        _buildQuickActionCard(
                          context,
                          icon: Icons.event_available,
                          title: isRTL ? 'جدولة اجتماع' : 'Schedule Meeting',
                          subtitle: isRTL ? 'إنشاء اجتماع جديد' : 'Create new meeting',
                          color: AppColors.gentleGreen,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MeetingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.announcement,
                          title: isRTL ? 'إرسال إعلان' : 'Send Announcement',
                          subtitle: isRTL ? 'إنشاء إعلان جديد' : 'Create new announcement',
                          color: AppColors.gentleOrange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnnouncementsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.description,
                          title: isRTL ? 'الوثائق' : 'Documents',
                          subtitle: isRTL ? 'الوصول للوثائق' : 'Access documents',
                          color: AppColors.gentlePurple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DocumentsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.track_changes,
                          title: isRTL ? 'تتبع سير العمل' : 'Workflow Tracking',
                          subtitle: isRTL ? 'تتبع الطلبات والمعاملات' : 'Track requests and transactions',
                          color: AppColors.infoColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WorkflowScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.people_outline,
                          title: isRTL ? 'دليل الموظفين' : 'Employee Directory',
                          subtitle: isRTL ? 'البحث عن الزملاء' : 'Find colleagues',
                          color: AppColors.gentlePink,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DirectoryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.message,
                          title: isRTL ? 'الرسائل' : 'Messages',
                          subtitle: isRTL ? 'بدء محادثة جديدة' : 'Start new conversation',
                          color: AppColors.secondaryColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MessagingScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppConstants.largePadding),

                // Today's Schedule
                Text(
                  isRTL ? 'جدول اليوم' : "Today's Schedule",
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                _buildTodaysScheduleCard(context, isRTL, userId),

                const SizedBox(height: AppConstants.largePadding),

                // Recent Announcements
                Text(
                  isRTL ? 'الإعلانات الحديثة' : 'Recent Announcements',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                _buildRecentAnnouncementsCard(context, isRTL, user),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.smallPadding,
            vertical: AppConstants.smallPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysScheduleCard(BuildContext context, bool isRTL, String userId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.today_outlined,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    AppDateUtils.formatDate(DateTime.now(), locale: isRTL ? 'ar' : 'en'),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            StreamBuilder<List<MeetingModel>>(
              stream: _meetingService.getTodaysMeetingsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 48,
                          color: AppColors.textLightColor,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          isRTL ? 'لا توجد اجتماعات اليوم' : 'No meetings today',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                final meetings = snapshot.data!;
                return Column(
                  children: meetings.take(3).map((meeting) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.event,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        meeting.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${AppDateUtils.formatTime(meeting.startTime)} - ${meeting.location}',
                        style: AppTextStyles.bodySmall,
                      ),
                      onTap: () {
                        // TODO: Navigate to meeting details
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAnnouncementsCard(BuildContext context, bool isRTL, user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.announcement_outlined,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      Flexible(
                        child: Text(
                          isRTL ? 'الإعلانات' : 'Announcements',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnnouncementsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    isRTL ? 'عرض الكل' : 'View All',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            StreamBuilder<List<AnnouncementModel>>(
              stream: _announcementService.getAnnouncementsForUser(
                userId: user?.id ?? '',
                userDepartment: user?.department ?? '',
                userRoles: user?.roles ?? [],
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 48,
                          color: AppColors.textLightColor,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          isRTL ? 'لا توجد إعلانات جديدة' : 'No new announcements',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                final announcements = snapshot.data!;
                return Column(
                  children: announcements.take(3).map((announcement) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPriorityColor(announcement.priority).withValues(alpha: 0.1),
                        child: Icon(
                          Icons.announcement,
                          color: _getPriorityColor(announcement.priority),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        announcement.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        AppDateUtils.formatDate(announcement.createdAt, locale: isRTL ? 'ar' : 'en'),
                        style: AppTextStyles.bodySmall,
                      ),
                      onTap: () {
                        // TODO: Show announcement details
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.urgent:
        return Colors.red;
      case AnnouncementPriority.high:
        return Colors.orange;
      case AnnouncementPriority.normal:
        return AppColors.primaryColor;
      case AnnouncementPriority.low:
        return Colors.grey;
    }
  }
}