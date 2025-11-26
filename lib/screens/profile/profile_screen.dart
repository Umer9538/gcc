import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../services/user_service.dart';
import '../../utils/date_utils.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<app_auth.AuthProvider, AppProvider>(
      builder: (context, authProvider, appProvider, child) {
        final user = authProvider.currentUser;
        final isRTL = appProvider.isRTL;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(
              isRTL ? 'الملف الشخصي' : 'Profile',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: user),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppConstants.largePadding),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: user?.profileImageUrl != null
                            ? NetworkImage(user!.profileImageUrl!)
                            : null,
                        child: user?.profileImageUrl == null
                            ? Text(
                                user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                                style: AppTextStyles.heading1.copyWith(
                                  color: AppColors.primaryColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      Text(
                        user?.fullName ?? (isRTL ? 'مستخدم' : 'User'),
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        user?.email ?? '',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        '${user?.position ?? ''} • ${user?.department ?? ''}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: AppConstants.largePadding),
                    ],
                  ),
                ),

                // Profile Details
                Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    children: [
                      // Personal Information
                      _buildSectionCard(
                        context,
                        title: isRTL ? 'المعلومات الشخصية' : 'Personal Information',
                        icon: Icons.person_outline,
                        children: [
                          _buildInfoTile(
                            icon: Icons.badge_outlined,
                            title: isRTL ? 'الاسم الأول' : 'First Name',
                            value: user?.firstName ?? '',
                          ),
                          _buildInfoTile(
                            icon: Icons.badge_outlined,
                            title: isRTL ? 'الاسم الأخير' : 'Last Name',
                            value: user?.lastName ?? '',
                          ),
                          _buildInfoTile(
                            icon: Icons.phone_outlined,
                            title: isRTL ? 'رقم الهاتف' : 'Phone Number',
                            value: user?.phoneNumber ?? '',
                            forceLtr: true,
                          ),
                          _buildInfoTile(
                            icon: Icons.calendar_today_outlined,
                            title: isRTL ? 'تاريخ الانضمام' : 'Joined Date',
                            value: user?.createdAt != null
                                ? AppDateUtils.formatDate(user!.createdAt!, locale: isRTL ? 'ar' : 'en')
                                : '',
                          ),
                          _buildInfoTile(
                            icon: Icons.login_outlined,
                            title: isRTL ? 'آخر تسجيل دخول' : 'Last Login',
                            value: user?.lastLogin != null
                                ? AppDateUtils.formatDate(user!.lastLogin!, locale: isRTL ? 'ar' : 'en')
                                : '',
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.defaultPadding),

                      // Work Information
                      _buildSectionCard(
                        context,
                        title: isRTL ? 'معلومات العمل' : 'Work Information',
                        icon: Icons.work_outline,
                        children: [
                          _buildInfoTile(
                            icon: Icons.business_outlined,
                            title: isRTL ? 'القسم' : 'Department',
                            value: user?.department ?? '',
                          ),
                          _buildInfoTile(
                            icon: Icons.work_outline,
                            title: isRTL ? 'المنصب' : 'Position',
                            value: user?.position ?? '',
                          ),
                          _buildInfoTile(
                            icon: Icons.security_outlined,
                            title: isRTL ? 'الأدوار' : 'Roles',
                            value: user?.roles.join(', ') ?? '',
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.defaultPadding),

                      // Settings
                      _buildSectionCard(
                        context,
                        title: isRTL ? 'الإعدادات' : 'Settings',
                        icon: Icons.settings_outlined,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.language_outlined),
                            title: Text(isRTL ? 'اللغة' : 'Language'),
                            subtitle: Text(
                              isRTL ? 'العربية' : 'English',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              _showLanguageDialog(context, appProvider, isRTL);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.dark_mode_outlined),
                            title: Text(isRTL ? 'المظهر' : 'Theme'),
                            subtitle: Text(
                              _getThemeText(appProvider.themeMode, isRTL),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              _showThemeDialog(context, appProvider, isRTL);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: Text(isRTL ? 'الإشعارات' : 'Notifications'),
                            trailing: Switch(
                              value: true,
                              onChanged: (value) {
                                // TODO: Toggle notifications
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.defaultPadding),

                      // Actions
                      _buildSectionCard(
                        context,
                        title: isRTL ? 'الإجراءات' : 'Actions',
                        icon: Icons.more_horiz_outlined,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.help_outline, color: AppColors.infoColor),
                            title: Text(isRTL ? 'المساعدة والدعم' : 'Help & Support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to help
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.warningColor),
                            title: Text(isRTL ? 'سياسة الخصوصية' : 'Privacy Policy'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Show privacy policy
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout, color: AppColors.errorColor),
                            title: Text(
                              isRTL ? 'تسجيل الخروج' : 'Sign Out',
                              style: const TextStyle(color: AppColors.errorColor),
                            ),
                            onTap: () {
                              _showSignOutDialog(context, authProvider, isRTL);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.largePadding),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryColor),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  title,
                  style: AppTextStyles.heading3,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool forceLtr = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondaryColor,
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                forceLtr
                    ? Directionality(
                        textDirection: TextDirection.ltr,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            value.isNotEmpty ? value : '-',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      )
                    : Text(
                        value.isNotEmpty ? value : '-',
                        style: AppTextStyles.bodyMedium,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeText(ThemeMode themeMode, bool isRTL) {
    switch (themeMode) {
      case ThemeMode.light:
        return isRTL ? 'فاتح' : 'Light';
      case ThemeMode.dark:
        return isRTL ? 'داكن' : 'Dark';
      case ThemeMode.system:
        return isRTL ? 'تلقائي' : 'System';
    }
  }

  void _showLanguageDialog(BuildContext context, AppProvider appProvider, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'اختر اللغة' : 'Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: appProvider.locale.languageCode,
                onChanged: (value) {
                  appProvider.changeLanguage('en');
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('العربية'),
              leading: Radio<String>(
                value: 'ar',
                groupValue: appProvider.locale.languageCode,
                onChanged: (value) {
                  appProvider.changeLanguage('ar');
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, AppProvider appProvider, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'اختر المظهر' : 'Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(isRTL ? 'فاتح' : 'Light'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: appProvider.themeMode,
                onChanged: (value) {
                  appProvider.changeTheme(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text(isRTL ? 'داكن' : 'Dark'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: appProvider.themeMode,
                onChanged: (value) {
                  appProvider.changeTheme(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text(isRTL ? 'تلقائي' : 'System'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: appProvider.themeMode,
                onChanged: (value) {
                  appProvider.changeTheme(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, app_auth.AuthProvider authProvider, bool isRTL) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isRTL ? 'تسجيل الخروج' : 'Sign Out'),
        content: Text(
          isRTL
              ? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟'
              : 'Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await authProvider.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: Text(isRTL ? 'تسجيل الخروج' : 'Sign Out'),
          ),
        ],
      ),
    );
  }
}