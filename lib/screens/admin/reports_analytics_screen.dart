import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/shimmer_loading.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    final authProvider = Provider.of<AuthProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final isRTL = appProvider.isRTL;
    final isWeb = kIsWeb;
    final user = authProvider.currentUser;

    // Check if user is Super Admin
    if (!user!.roles.contains('super_admin')) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isRTL ? 'التقارير والتحليلات' : 'Reports & Analytics'),
          backgroundColor: AppColors.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: AppColors.errorColor),
              const SizedBox(height: 16),
              Text(
                isRTL ? 'غير مصرح' : 'Unauthorized',
                style: AppTextStyles.heading2.copyWith(color: AppColors.errorColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(isRTL ? 'التقارير والتحليلات' : 'Reports & Analytics'),
        backgroundColor: const Color(0xFF4CAF50),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.dashboard),
              text: isRTL ? 'لوحة المعلومات' : 'Overview',
            ),
            Tab(
              icon: const Icon(Icons.people),
              text: isRTL ? 'المستخدمون' : 'Users',
            ),
            Tab(
              icon: const Icon(Icons.announcement),
              text: isRTL ? 'الإعلانات' : 'Announcements',
            ),
            Tab(
              icon: const Icon(Icons.event),
              text: isRTL ? 'الاجتماعات' : 'Meetings',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(isRTL, isWeb),
          _buildUsersTab(isRTL, isWeb),
          _buildAnnouncementsTab(isRTL, isWeb),
          _buildMeetingsTab(isRTL, isWeb),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isRTL, bool isWeb) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Stats
          Text(
            isRTL ? 'إحصائيات النظام' : 'System Statistics',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('announcements').snapshots(),
                builder: (context, announcementSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('meetings').snapshots(),
                    builder: (context, meetingSnapshot) {
                      if (!userSnapshot.hasData || !announcementSnapshot.hasData || !meetingSnapshot.hasData) {
                        return ShimmerLoading.gridItem(isWeb: isWeb);
                      }

                      final totalUsers = userSnapshot.data!.docs.length;
                      final totalAnnouncements = announcementSnapshot.data!.docs.length;
                      final totalMeetings = meetingSnapshot.data!.docs.length;

                      final activeUsers = userSnapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['isActive'] == true;
                      }).length;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWeb ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWeb ? 1.5 : 1.3,
                        children: [
                          _buildStatCard(
                            title: isRTL ? 'إجمالي المستخدمين' : 'Total Users',
                            value: totalUsers.toString(),
                            icon: Icons.people,
                            color: AppColors.primaryColor,
                          ),
                          _buildStatCard(
                            title: isRTL ? 'مستخدمون نشطون' : 'Active Users',
                            value: activeUsers.toString(),
                            icon: Icons.person_outline,
                            color: AppColors.successColor,
                          ),
                          _buildStatCard(
                            title: isRTL ? 'الإعلانات' : 'Announcements',
                            value: totalAnnouncements.toString(),
                            icon: Icons.announcement,
                            color: AppColors.gentleOrange,
                          ),
                          _buildStatCard(
                            title: isRTL ? 'الاجتماعات' : 'Meetings',
                            value: totalMeetings.toString(),
                            icon: Icons.event,
                            color: AppColors.infoColor,
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 32),

          // Recent Activity
          Text(
            isRTL ? 'النشاط الأخير' : 'Recent Activity',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .orderBy('lastLogin', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ShimmerLoading.listItem(isWeb: isWeb, count: 5);
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['fullName'] ?? 'Unknown';
                  final lastLogin = (data['lastLogin'] as Timestamp?)?.toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                        child: Icon(Icons.person, color: AppColors.primaryColor),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        lastLogin != null
                            ? (isRTL
                                ? 'آخر دخول: ${_formatDateTime(lastLogin)}'
                                : 'Last login: ${_formatDateTime(lastLogin)}')
                            : (isRTL ? 'لم يسجل دخول بعد' : 'Never logged in'),
                      ),
                      trailing: Icon(
                        Icons.circle,
                        size: 12,
                        color: _isRecentlyActive(lastLogin)
                            ? AppColors.successColor
                            : AppColors.textLightColor,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(bool isRTL, bool isWeb) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRTL ? 'تقرير المستخدمين' : 'User Report',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ShimmerLoading.gridItem(isWeb: isWeb);
              }

              final users = snapshot.data!.docs;
              final roleStats = <String, int>{};
              final departmentStats = <String, int>{};

              for (var doc in users) {
                final data = doc.data() as Map<String, dynamic>;
                final roles = List<String>.from(data['roles'] ?? []);
                final department = data['department'] ?? 'Unknown';

                for (var role in roles) {
                  roleStats[role] = (roleStats[role] ?? 0) + 1;
                }
                departmentStats[department] = (departmentStats[department] ?? 0) + 1;
              }

              return Column(
                children: [
                  _buildChartCard(
                    title: isRTL ? 'المستخدمون حسب الدور' : 'Users by Role',
                    stats: roleStats,
                    isRTL: isRTL,
                  ),
                  const SizedBox(height: 16),
                  _buildChartCard(
                    title: isRTL ? 'المستخدمون حسب القسم' : 'Users by Department',
                    stats: departmentStats,
                    isRTL: isRTL,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab(bool isRTL, bool isWeb) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRTL ? 'تقرير الإعلانات' : 'Announcements Report',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('announcements').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ShimmerLoading.listItem(isWeb: isWeb, count: 3);
              }

              final announcements = snapshot.data!.docs;
              final total = announcements.length;
              final active = announcements.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isActive'] == true;
              }).length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: isRTL ? 'إجمالي الإعلانات' : 'Total Announcements',
                          value: total.toString(),
                          icon: Icons.announcement,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: isRTL ? 'إعلانات نشطة' : 'Active Announcements',
                          value: active.toString(),
                          icon: Icons.check_circle,
                          color: AppColors.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsTab(bool isRTL, bool isWeb) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRTL ? 'تقرير الاجتماعات' : 'Meetings Report',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('meetings').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ShimmerLoading.listItem(isWeb: isWeb, count: 3);
              }

              final meetings = snapshot.data!.docs;
              final total = meetings.length;
              final now = DateTime.now();

              final upcoming = meetings.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final startTime = (data['startTime'] as Timestamp).toDate();
                return startTime.isAfter(now);
              }).length;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: isRTL ? 'إجمالي الاجتماعات' : 'Total Meetings',
                      value: total.toString(),
                      icon: Icons.event,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: isRTL ? 'اجتماعات قادمة' : 'Upcoming Meetings',
                      value: upcoming.toString(),
                      icon: Icons.event_available,
                      color: AppColors.successColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required Map<String, int> stats,
    required bool isRTL,
  }) {
    final total = stats.values.fold(0, (sum, val) => sum + val);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...stats.entries.map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          '${entry.value} ($percentage%)',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / total,
                      backgroundColor: AppColors.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  bool _isRecentlyActive(DateTime? lastLogin) {
    if (lastLogin == null) return false;
    final difference = DateTime.now().difference(lastLogin);
    return difference.inMinutes < 30;
  }
}
