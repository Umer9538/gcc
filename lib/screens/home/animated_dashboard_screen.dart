import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/date_utils.dart';
import '../../services/meeting_service.dart';
import '../../services/announcement_service.dart';
import '../../models/meeting_model.dart';
import '../../models/announcement_model.dart';
import '../../widgets/loading_overlay.dart';
import '../meetings/meetings_screen.dart';
import '../announcements/announcements_screen.dart';
import '../directory/directory_screen.dart';
import '../documents/documents_screen.dart';
import '../workflow/workflow_screen.dart';
import '../messaging/messaging_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../admin/user_management_screen.dart';

class AnimatedDashboardScreen extends StatefulWidget {
  const AnimatedDashboardScreen({super.key});

  @override
  State<AnimatedDashboardScreen> createState() => _AnimatedDashboardScreenState();
}

class _AnimatedDashboardScreenState extends State<AnimatedDashboardScreen> {
  final MeetingService _meetingService = MeetingService();
  final AnnouncementService _announcementService = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 800;
    final isMobile = size.width < 600;

    return Consumer2<app_auth.AuthProvider, AppProvider>(
      builder: (context, authProvider, appProvider, child) {
        final user = authProvider.currentUser;
        final isRTL = appProvider.isRTL;
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: FadeIn(
              child: Text(
                isRTL ? 'لوحة التحكم' : 'Dashboard',
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
            ),
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            actions: [
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Navigate to notifications
                  },
                ),
              ),
              FadeIn(
                delay: const Duration(milliseconds: 300),
                child: IconButton(
                  icon: const Icon(Icons.search_outlined),
                  onPressed: () {
                    // TODO: Open search
                  },
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card with Animation
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildWelcomeCard(user, appProvider, isWeb, isMobile),
                ),

                SizedBox(height: isWeb ? 32 : 24),

                // Quick Actions Section
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    isRTL ? 'الإجراءات السريعة' : 'Quick Actions',
                    style: isWeb ? AppTextStyles.heading2 : AppTextStyles.heading3,
                  ),
                ),
                SizedBox(height: isWeb ? 20 : 16),

                // Quick Actions Grid with Staggered Animation
                _buildQuickActionsGrid(context, isRTL, isWeb, isMobile),

                SizedBox(height: isWeb ? 32 : 24),

                // Today's Schedule Section
                FadeInLeft(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    isRTL ? 'جدول اليوم' : "Today's Schedule",
                    style: isWeb ? AppTextStyles.heading2 : AppTextStyles.heading3,
                  ),
                ),
                SizedBox(height: isWeb ? 20 : 16),

                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: _buildTodaysScheduleCard(context, isRTL, userId, isWeb),
                ),

                SizedBox(height: isWeb ? 32 : 24),

                // Recent Announcements Section
                FadeInLeft(
                  delay: const Duration(milliseconds: 600),
                  child: Text(
                    isRTL ? 'الإعلانات الحديثة' : 'Recent Announcements',
                    style: isWeb ? AppTextStyles.heading2 : AppTextStyles.heading3,
                  ),
                ),
                SizedBox(height: isWeb ? 20 : 16),

                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: _buildRecentAnnouncementsCard(context, isRTL, user, isWeb),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          floatingActionButton: FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: FloatingActionButton.extended(
              onPressed: () {
                context.navigateWithLoading(
                  const ChatbotScreen(),
                  loadingMessage: isRTL ? 'جارٍ التحميل...' : 'Loading AI Assistant...',
                );
              },
              backgroundColor: AppColors.secondaryColor,
              icon: const Icon(Icons.smart_toy, color: Colors.white),
              label: Text(
                isRTL ? 'مساعد ذكي' : 'AI Assistant',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(dynamic user, AppProvider appProvider, bool isWeb, bool isMobile) {
    final isRTL = appProvider.isRTL;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 32 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeIn(
            delay: const Duration(milliseconds: 300),
            child: Text(
              appProvider.getGreeting(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: isWeb ? 18 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: isWeb ? 12 : 8),
          FadeIn(
            delay: const Duration(milliseconds: 400),
            child: Text(
              user?.fullName ?? (isRTL ? 'مستخدم' : 'User'),
              style: TextStyle(
                color: Colors.white,
                fontSize: isWeb ? 32 : 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: isWeb ? 12 : 8),
          FadeIn(
            delay: const Duration(milliseconds: 500),
            child: Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: isWeb ? 20 : 16,
                ),
                const SizedBox(width: 8),
                Text(
                  user?.position ?? (isRTL ? 'المنصب' : 'Position'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: isWeb ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FadeIn(
            delay: const Duration(milliseconds: 600),
            child: Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: isWeb ? 20 : 16,
                ),
                const SizedBox(width: 8),
                Text(
                  user?.department ?? (isRTL ? 'القسم' : 'Department'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: isWeb ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isRTL, bool isWeb, bool isMobile) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = authProvider.currentUser;
    final isSuperAdmin = user?.roles.contains('super_admin') ?? false;

    final actions = [
      {
        'icon': Icons.event_available,
        'title': isRTL ? 'جدولة اجتماع' : 'Schedule Meeting',
        'subtitle': isRTL ? 'إنشاء اجتماع جديد' : 'Create new meeting',
        'color': AppColors.gentleGreen,
        'onTap': () => context.navigateWithLoading(const MeetingsScreen(), loadingMessage: isRTL ? 'جارٍ التحميل...' : 'Loading...'),
      },
      {
        'icon': Icons.announcement,
        'title': isRTL ? 'إرسال إعلان' : 'Send Announcement',
        'subtitle': isRTL ? 'إنشاء إعلان جديد' : 'Create new announcement',
        'color': AppColors.gentleOrange,
        'onTap': () => context.navigateWithLoading(const AnnouncementsScreen(), loadingMessage: isRTL ? 'جارٍ التحميل...' : 'Loading...'),
      },
      {
        'icon': Icons.description,
        'title': isRTL ? 'الوثائق' : 'Documents',
        'subtitle': isRTL ? 'الوصول للوثائق' : 'Access documents',
        'color': AppColors.gentlePurple,
        'onTap': () => context.navigateWithLoading(const DocumentsScreen(), loadingMessage: isRTL ? 'جارٍ التحميل...' : 'Loading...'),
      },
      {
        'icon': Icons.track_changes,
        'title': isRTL ? 'تتبع سير العمل' : 'Workflow Tracking',
        'subtitle': isRTL ? 'تتبع الطلبات' : 'Track requests',
        'color': AppColors.infoColor,
        'onTap': () => context.navigateWithLoading(const WorkflowScreen(), loadingMessage: isRTL ? 'جارٍ التحميل...' : 'Loading...'),
      },
      {
        'icon': Icons.people_outline,
        'title': isRTL ? 'دليل الموظفين' : 'Employee Directory',
        'subtitle': isRTL ? 'البحث عن الزملاء' : 'Find colleagues',
        'color': AppColors.gentlePink,
        'onTap': () => context.navigateWithLoading(const DirectoryScreen(), loadingMessage: isRTL ? 'جارٍ التحميل...' : 'Loading...'),
      },
      {
        'icon': Icons.message,
        'title': isRTL ? 'الرسائل' : 'Messages',
        'subtitle': isRTL ? 'بدء محادثة' : 'Start conversation',
        'color': AppColors.secondaryColor,
        'onTap': () => context.navigateWithLoading(const MessagingScreen(), loadingMessage: isRTL ? 'جارٍ التحميل...' : 'Loading...'),
      },
      if (isSuperAdmin)
        {
          'icon': Icons.admin_panel_settings,
          'title': isRTL ? 'إدارة المستخدمين' : 'User Management',
          'subtitle': isRTL ? 'إدارة أدوار المستخدمين' : 'Manage user roles',
          'color': const Color(0xFF9C27B0), // Purple for admin
          'onTap': () => context.navigateWithLoading(const UserManagementScreen(), loadingMessage: isRTL ? 'جارٍ التحميل...' : 'Loading...'),
        },
    ];

    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWeb ? 3 : (isMobile ? 2 : 3),
          crossAxisSpacing: isWeb ? 20 : 12,
          mainAxisSpacing: isWeb ? 20 : 12,
          childAspectRatio: isWeb ? 1.3 : 1.1,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 600),
            columnCount: isWeb ? 3 : 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildQuickActionCard(
                  context,
                  icon: actions[index]['icon'] as IconData,
                  title: actions[index]['title'] as String,
                  subtitle: actions[index]['subtitle'] as String,
                  color: actions[index]['color'] as Color,
                  onTap: actions[index]['onTap'] as VoidCallback,
                  isWeb: isWeb,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isWeb,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
            child: Container(
              padding: EdgeInsets.all(isWeb ? 20 : 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: isWeb ? 60 : 50,
                    height: isWeb ? 60 : 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isWeb ? 30 : 24,
                    ),
                  ),
                  SizedBox(height: isWeb ? 16 : 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isWeb ? 16 : 13,
                      color: AppColors.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isWeb ? 6 : 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isWeb ? 13 : 11,
                      color: AppColors.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysScheduleCard(BuildContext context, bool isRTL, String userId, bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.today_outlined,
                  color: AppColors.primaryColor,
                  size: isWeb ? 24 : 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppDateUtils.formatDate(DateTime.now(), locale: isRTL ? 'ar' : 'en'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isWeb ? 18 : 16,
                      color: AppColors.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isWeb ? 20 : 16),
            StreamBuilder<List<MeetingModel>>(
              stream: _meetingService.getTodaysMeetingsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingShimmer(isWeb);
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.event_busy_outlined,
                    message: isRTL ? 'لا توجد اجتماعات اليوم' : 'No meetings today',
                    isWeb: isWeb,
                  );
                }

                final meetings = snapshot.data!;
                return AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 500),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 50,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: meetings.take(3).map((meeting) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.event,
                              color: AppColors.primaryColor,
                              size: isWeb ? 22 : 20,
                            ),
                          ),
                          title: Text(
                            meeting.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isWeb ? 16 : 14,
                            ),
                          ),
                          subtitle: Text(
                            '${AppDateUtils.formatTime(meeting.startTime)} - ${meeting.location}',
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 12,
                            ),
                          ),
                          onTap: () {
                            // TODO: Navigate to meeting details
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAnnouncementsCard(BuildContext context, bool isRTL, dynamic user, bool isWeb) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
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
                        size: isWeb ? 24 : 20,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          isRTL ? 'الإعلانات' : 'Announcements',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isWeb ? 18 : 16,
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
                    context.navigateWithLoading(
                      const AnnouncementsScreen(),
                      loadingMessage: isRTL ? 'جارٍ التحميل...' : 'Loading...',
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
            SizedBox(height: isWeb ? 20 : 16),
            StreamBuilder<List<AnnouncementModel>>(
              stream: _announcementService.getAnnouncementsForUser(
                userId: user?.id ?? '',
                userDepartment: user?.department ?? '',
                userRoles: user?.roles ?? [],
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingShimmer(isWeb);
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.notifications_none_outlined,
                    message: isRTL ? 'لا توجد إعلانات جديدة' : 'No new announcements',
                    isWeb: isWeb,
                  );
                }

                final announcements = snapshot.data!;
                return AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 500),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 50,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: announcements.take(3).map((announcement) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getPriorityColor(announcement.priority).withValues(alpha: 0.1),
                            child: Icon(
                              Icons.announcement,
                              color: _getPriorityColor(announcement.priority),
                              size: isWeb ? 22 : 20,
                            ),
                          ),
                          title: Text(
                            announcement.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isWeb ? 16 : 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            AppDateUtils.formatDate(announcement.createdAt, locale: isRTL ? 'ar' : 'en'),
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 12,
                            ),
                          ),
                          onTap: () {
                            // TODO: Show announcement details
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isWeb) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: isWeb ? 50 : 40,
                  height: isWeb ? 50 : 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: isWeb ? 16 : 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: isWeb ? 14 : 12,
                        width: 150,
                        color: Colors.white,
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

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required bool isWeb,
  }) {
    return Center(
      child: Column(
        children: [
          Icon(
            icon,
            size: isWeb ? 64 : 48,
            color: AppColors.textLightColor,
          ),
          SizedBox(height: isWeb ? 16 : 12),
          Text(
            message,
            style: TextStyle(
              fontSize: isWeb ? 16 : 14,
              color: AppColors.textSecondaryColor,
            ),
          ),
        ],
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
