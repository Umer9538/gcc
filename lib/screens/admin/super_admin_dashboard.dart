import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../announcements/announcements_screen.dart';
import 'user_management_screen.dart';
import 'system_settings_screen.dart';
import 'reports_analytics_screen.dart';
import '../../widgets/loading_overlay.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          title: Text(isRTL ? 'لوحة المسؤول' : 'Admin Dashboard'),
          backgroundColor: AppColors.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: AppColors.errorColor,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                isRTL ? 'غير مصرح' : 'Unauthorized',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.errorColor,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                isRTL
                    ? 'هذه الصفحة متاحة فقط للمسؤولين العامين'
                    : 'This page is only accessible to Super Admins',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(isRTL ? 'لوحة المسؤول العام' : 'Super Admin Dashboard'),
        backgroundColor: const Color(0xFF9C27B0), // Purple
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: isRTL ? 'تحديث' : 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(user, isRTL, isWeb),

            SizedBox(height: isWeb ? 32 : 24),

            // Statistics Cards
            _buildStatisticsSection(isRTL, isWeb),

            SizedBox(height: isWeb ? 32 : 24),

            // Management Sections
            Text(
              isRTL ? 'الإدارة' : 'Management',
              style: AppTextStyles.heading2.copyWith(
                fontSize: isWeb ? 24 : 20,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            _buildManagementCards(context, isRTL, isWeb),

            SizedBox(height: isWeb ? 32 : 24),

            // Recent Activity
            Text(
              isRTL ? 'النشاط الأخير' : 'Recent Activity',
              style: AppTextStyles.heading2.copyWith(
                fontSize: isWeb ? 24 : 20,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            _buildRecentActivity(isRTL, isWeb),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, bool isRTL, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 24.0 : 20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isWeb ? 40 : 32,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Icon(
              Icons.admin_panel_settings,
              size: isWeb ? 48 : 40,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isWeb ? 24 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRTL ? 'مرحباً، ${user.fullName}' : 'Welcome, ${user.fullName}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWeb ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRTL ? 'مسؤول عام' : 'Super Administrator',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isWeb ? 16 : 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: isWeb ? 16 : 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRTL ? 'صلاحيات كاملة' : 'Full Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWeb ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(bool isRTL, bool isWeb) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;
        final totalUsers = users.length;
        final superAdmins = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final roles = List<String>.from(data['roles'] ?? []);
          return roles.contains('super_admin');
        }).length;
        final admins = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final roles = List<String>.from(data['roles'] ?? []);
          return roles.contains('admin');
        }).length;
        final hrs = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final roles = List<String>.from(data['roles'] ?? []);
          return roles.contains('hr');
        }).length;
        final managers = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final roles = List<String>.from(data['roles'] ?? []);
          return roles.contains('manager');
        }).length;
        final employees = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final roles = List<String>.from(data['roles'] ?? []);
          return roles.contains('employee');
        }).length;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWeb ? 3 : 2,
          crossAxisSpacing: isWeb ? 20 : 12,
          mainAxisSpacing: isWeb ? 20 : 12,
          childAspectRatio: isWeb ? 1.8 : 1.5,
          children: [
            _buildStatCard(
              icon: Icons.people,
              title: isRTL ? 'إجمالي المستخدمين' : 'Total Users',
              count: totalUsers.toString(),
              color: AppColors.primaryColor,
              isWeb: isWeb,
            ),
            _buildStatCard(
              icon: Icons.admin_panel_settings,
              title: isRTL ? 'مسؤولون عامون' : 'Super Admins',
              count: superAdmins.toString(),
              color: const Color(0xFF9C27B0),
              isWeb: isWeb,
            ),
            _buildStatCard(
              icon: Icons.shield,
              title: isRTL ? 'مسؤولون' : 'Admins',
              count: admins.toString(),
              color: const Color(0xFFE91E63),
              isWeb: isWeb,
            ),
            _buildStatCard(
              icon: Icons.work,
              title: isRTL ? 'موارد بشرية' : 'HR',
              count: hrs.toString(),
              color: const Color(0xFF2196F3),
              isWeb: isWeb,
            ),
            _buildStatCard(
              icon: Icons.group,
              title: isRTL ? 'مديرون' : 'Managers',
              count: managers.toString(),
              color: const Color(0xFF009688),
              isWeb: isWeb,
            ),
            _buildStatCard(
              icon: Icons.person,
              title: isRTL ? 'موظفون' : 'Employees',
              count: employees.toString(),
              color: const Color(0xFF607D8B),
              isWeb: isWeb,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    required bool isWeb,
  }) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 20.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isWeb ? 40 : 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: isWeb ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryColor,
              fontSize: isWeb ? 14 : 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCards(BuildContext context, bool isRTL, bool isWeb) {
    final cards = [
      {
        'icon': Icons.people_alt,
        'title': isRTL ? 'إدارة المستخدمين' : 'User Management',
        'description': isRTL
            ? 'إدارة أدوار وصلاحيات المستخدمين'
            : 'Manage user roles and permissions',
        'color': const Color(0xFF9C27B0),
        'onTap': () => context.navigateWithLoading(const UserManagementScreen()),
      },
      {
        'icon': Icons.announcement,
        'title': isRTL ? 'إدارة الإعلانات' : 'Announcements',
        'description': isRTL
            ? 'إنشاء وإدارة الإعلانات'
            : 'Create and manage announcements',
        'color': AppColors.gentleOrange,
        'onTap': () => context.navigateWithLoading(const AnnouncementsScreen()),
      },
      {
        'icon': Icons.settings,
        'title': isRTL ? 'إعدادات النظام' : 'System Settings',
        'description': isRTL
            ? 'تكوين إعدادات التطبيق'
            : 'Configure application settings',
        'color': AppColors.infoColor,
        'onTap': () => context.navigateWithLoading(const SystemSettingsScreen()),
      },
      {
        'icon': Icons.analytics,
        'title': isRTL ? 'التقارير والتحليلات' : 'Reports & Analytics',
        'description': isRTL
            ? 'عرض الإحصائيات والتقارير'
            : 'View statistics and reports',
        'color': AppColors.successColor,
        'onTap': () => context.navigateWithLoading(const ReportsAnalyticsScreen()),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWeb ? 2 : 1,
        crossAxisSpacing: isWeb ? 20 : 12,
        mainAxisSpacing: isWeb ? 20 : 12,
        childAspectRatio: isWeb ? 2.5 : 2.8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return InkWell(
          onTap: card['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Container(
            padding: EdgeInsets.all(isWeb ? 24.0 : 20.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(
                color: (card['color'] as Color).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: (card['color'] as Color).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isWeb ? 16.0 : 14.0),
                  decoration: BoxDecoration(
                    color: (card['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    card['icon'] as IconData,
                    size: isWeb ? 32 : 28,
                    color: card['color'] as Color,
                  ),
                ),
                SizedBox(width: isWeb ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card['title'] as String,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isWeb ? 18 : 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card['description'] as String,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryColor,
                          fontSize: isWeb ? 14 : 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: isWeb ? 20 : 16,
                  color: AppColors.textLightColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(bool isRTL, bool isWeb) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .orderBy('lastLogin', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isRTL ? 'لا يوجد نشاط حديث' : 'No recent activity',
              style: AppTextStyles.bodyMedium,
            ),
          );
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
              margin: EdgeInsets.only(bottom: isWeb ? 12.0 : 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primaryColor,
                  ),
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
