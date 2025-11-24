import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Settings values
  bool _maintenanceMode = false;
  bool _allowRegistration = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  int _sessionTimeout = 30;
  int _maxUploadSize = 10;
  String _appVersion = '1.0.0';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore.collection('system_settings').doc('config').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _allowRegistration = data['allowRegistration'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? true;
          _pushNotifications = data['pushNotifications'] ?? true;
          _sessionTimeout = data['sessionTimeout'] ?? 30;
          _maxUploadSize = data['maxUploadSize'] ?? 10;
          _appVersion = data['appVersion'] ?? '1.0.0';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _firestore.collection('system_settings').doc('config').set({
        'maintenanceMode': _maintenanceMode,
        'allowRegistration': _allowRegistration,
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
        'sessionTimeout': _sessionTimeout,
        'maxUploadSize': _maxUploadSize,
        'appVersion': _appVersion,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
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
          title: Text(isRTL ? 'إعدادات النظام' : 'System Settings'),
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isRTL ? 'إعدادات النظام' : 'System Settings'),
          backgroundColor: AppColors.primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(isRTL ? 'إعدادات النظام' : 'System Settings'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: isRTL ? 'حفظ' : 'Save',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            _buildSectionHeader(isRTL ? 'إعدادات عامة' : 'General Settings', Icons.settings),
            const SizedBox(height: 16),
            _buildSettingCard(
              title: isRTL ? 'وضع الصيانة' : 'Maintenance Mode',
              subtitle: isRTL
                  ? 'إيقاف الوصول للتطبيق مؤقتاً'
                  : 'Temporarily disable access to the app',
              child: Switch(
                value: _maintenanceMode,
                onChanged: (value) {
                  setState(() => _maintenanceMode = value);
                },
                activeColor: AppColors.primaryColor,
              ),
            ),
            _buildSettingCard(
              title: isRTL ? 'السماح بالتسجيل' : 'Allow Registration',
              subtitle: isRTL
                  ? 'السماح للمستخدمين الجدد بإنشاء حسابات'
                  : 'Allow new users to create accounts',
              child: Switch(
                value: _allowRegistration,
                onChanged: (value) {
                  setState(() => _allowRegistration = value);
                },
                activeColor: AppColors.primaryColor,
              ),
            ),
            _buildSettingCard(
              title: isRTL ? 'إصدار التطبيق' : 'App Version',
              subtitle: isRTL ? 'رقم إصدار التطبيق الحالي' : 'Current app version number',
              child: SizedBox(
                width: 100,
                child: TextField(
                  controller: TextEditingController(text: _appVersion),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => _appVersion = value,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Notification Settings
            _buildSectionHeader(isRTL ? 'إعدادات الإشعارات' : 'Notification Settings', Icons.notifications),
            const SizedBox(height: 16),
            _buildSettingCard(
              title: isRTL ? 'إشعارات البريد الإلكتروني' : 'Email Notifications',
              subtitle: isRTL
                  ? 'إرسال إشعارات عبر البريد الإلكتروني'
                  : 'Send notifications via email',
              child: Switch(
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                },
                activeColor: AppColors.primaryColor,
              ),
            ),
            _buildSettingCard(
              title: isRTL ? 'الإشعارات الفورية' : 'Push Notifications',
              subtitle: isRTL
                  ? 'إرسال إشعارات فورية للمستخدمين'
                  : 'Send push notifications to users',
              child: Switch(
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                },
                activeColor: AppColors.primaryColor,
              ),
            ),

            const SizedBox(height: 32),

            // Security Settings
            _buildSectionHeader(isRTL ? 'إعدادات الأمان' : 'Security Settings', Icons.security),
            const SizedBox(height: 16),
            _buildSettingCard(
              title: isRTL ? 'مهلة الجلسة (دقائق)' : 'Session Timeout (minutes)',
              subtitle: isRTL
                  ? 'مدة عدم النشاط قبل تسجيل الخروج التلقائي'
                  : 'Inactivity duration before auto-logout',
              child: SizedBox(
                width: 100,
                child: DropdownButtonFormField<int>(
                  value: _sessionTimeout,
                  items: [15, 30, 60, 120].map((min) {
                    return DropdownMenuItem(
                      value: min,
                      child: Text('$min ${isRTL ? 'دقيقة' : 'min'}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _sessionTimeout = value!);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // File Upload Settings
            _buildSectionHeader(isRTL ? 'إعدادات رفع الملفات' : 'File Upload Settings', Icons.upload_file),
            const SizedBox(height: 16),
            _buildSettingCard(
              title: isRTL ? 'الحد الأقصى لحجم الملف (MB)' : 'Max Upload Size (MB)',
              subtitle: isRTL
                  ? 'الحد الأقصى لحجم الملف المسموح به'
                  : 'Maximum allowed file size',
              child: SizedBox(
                width: 100,
                child: DropdownButtonFormField<int>(
                  value: _maxUploadSize,
                  items: [5, 10, 20, 50, 100].map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text('$size MB'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _maxUploadSize = value!);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  isRTL ? 'حفظ الإعدادات' : 'Save Settings',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 48 : 32,
                    vertical: isWeb ? 20 : 16,
                  ),
                ),
                onPressed: _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(fontSize: 20),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
