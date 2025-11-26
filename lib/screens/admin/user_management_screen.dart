import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/shimmer_loading.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final isRTL = appProvider.isRTL;
    final isWeb = kIsWeb;

    // Check if user is Super Admin
    if (!authProvider.currentUser!.roles.contains('super_admin')) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isRTL ? 'إدارة المستخدمين' : 'User Management'),
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
        title: Text(isRTL ? 'إدارة المستخدمين' : 'User Management'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterRole = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Text(isRTL ? 'الكل' : 'All Users'),
              ),
              PopupMenuItem(
                value: 'super_admin',
                child: Text(isRTL ? 'مسؤول عام' : 'Super Admin'),
              ),
              PopupMenuItem(
                value: 'admin',
                child: Text(isRTL ? 'مسؤول' : 'Admin'),
              ),
              PopupMenuItem(
                value: 'hr',
                child: Text(isRTL ? 'موارد بشرية' : 'HR'),
              ),
              PopupMenuItem(
                value: 'manager',
                child: Text(isRTL ? 'مدير' : 'Manager'),
              ),
              PopupMenuItem(
                value: 'employee',
                child: Text(isRTL ? 'موظف' : 'Employee'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
            color: AppColors.surfaceColor,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: isRTL ? 'ابحث عن مستخدم...' : 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                filled: true,
                fillColor: AppColors.backgroundColor,
              ),
            ),
          ),

          // Filter Badge
          if (_filterRole != 'all')
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              color: AppColors.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Text(
                    isRTL ? 'تصفية حسب: ' : 'Filter by: ',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Chip(
                    label: Text(_getRoleDisplayName(_filterRole, isRTL)),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _filterRole = 'all';
                      });
                    },
                  ),
                ],
              ),
            ),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ShimmerLoading.listItem(isWeb: isWeb, count: 8);
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      isRTL ? 'خطأ في تحميل المستخدمين' : 'Error loading users',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.errorColor,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      isRTL ? 'لا يوجد مستخدمين' : 'No users found',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }

                var users = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  users = users.where((user) {
                    return user.fullName.toLowerCase().contains(_searchQuery) ||
                        user.email.toLowerCase().contains(_searchQuery) ||
                        user.department.toLowerCase().contains(_searchQuery) ||
                        user.position.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                // Apply role filter
                if (_filterRole != 'all') {
                  users = users.where((user) {
                    return user.roles.contains(_filterRole);
                  }).toList();
                }

                // Sort by name
                users.sort((a, b) => a.fullName.compareTo(b.fullName));

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      isRTL ? 'لا توجد نتائج' : 'No results found',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(user, isRTL, isWeb);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user, bool isRTL, bool isWeb) {
    return Card(
      margin: EdgeInsets.only(bottom: isWeb ? 16.0 : 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: () => _showUserDetailsDialog(user, isRTL),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 20.0 : 16.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: isWeb ? 30 : 24,
                backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                backgroundImage: user.profileImageUrl?.isNotEmpty == true
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl?.isEmpty != false
                    ? Text(
                        _getInitials(user.fullName),
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isWeb ? 18 : 16,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: isWeb ? 20 : 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isWeb ? 18 : 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.position,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.department,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: user.roles.map((role) {
                        return Chip(
                          label: Text(
                            _getRoleDisplayName(role, isRTL),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                          backgroundColor: _getRoleColor(role),
                          padding: const EdgeInsets.all(0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit),
                color: AppColors.primaryColor,
                onPressed: () => _showEditRoleDialog(user, isRTL),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetailsDialog(UserModel user, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'تفاصيل المستخدم' : 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(isRTL ? 'الاسم' : 'Name', user.fullName, isRTL),
              _buildDetailRow(isRTL ? 'البريد الإلكتروني' : 'Email', user.email, isRTL, forceLtr: true),
              _buildDetailRow(isRTL ? 'الهاتف' : 'Phone', user.phoneNumber ?? 'N/A', isRTL, forceLtr: true),
              _buildDetailRow(isRTL ? 'القسم' : 'Department', user.department, isRTL),
              _buildDetailRow(isRTL ? 'المنصب' : 'Position', user.position, isRTL),
              _buildDetailRow(
                isRTL ? 'الأدوار' : 'Roles',
                user.roles.map((r) => _getRoleDisplayName(r, isRTL)).join(', '),
                isRTL,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isRTL, {bool forceLtr = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          forceLtr
              ? Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: AppTextStyles.bodyMedium,
                ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(UserModel user, bool isRTL) {
    List<String> selectedRoles = List.from(user.roles);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isRTL ? 'تعديل أدوار المستخدم' : 'Edit User Roles'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  isRTL ? 'اختر الأدوار:' : 'Select Roles:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                ...[
                  'employee',
                  'manager',
                  'hr',
                  'admin',
                  'super_admin',
                ].map((role) {
                  return CheckboxListTile(
                    title: Text(_getRoleDisplayName(role, isRTL)),
                    value: selectedRoles.contains(role),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          if (!selectedRoles.contains(role)) {
                            selectedRoles.add(role);
                          }
                        } else {
                          selectedRoles.remove(role);
                        }
                      });
                    },
                    activeColor: AppColors.primaryColor,
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isRTL ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedRoles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isRTL
                            ? 'يجب اختيار دور واحد على الأقل'
                            : 'At least one role must be selected',
                      ),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                  return;
                }

                try {
                  await _firestore.collection('users').doc(user.id).update({
                    'roles': selectedRoles,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRTL
                              ? 'تم تحديث أدوار المستخدم بنجاح'
                              : 'User roles updated successfully',
                        ),
                        backgroundColor: AppColors.successColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRTL ? 'فشل تحديث الأدوار' : 'Failed to update roles',
                        ),
                        backgroundColor: AppColors.errorColor,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: Text(
                isRTL ? 'حفظ' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role, bool isRTL) {
    if (isRTL) {
      switch (role) {
        case 'super_admin':
          return 'مسؤول عام';
        case 'admin':
          return 'مسؤول';
        case 'hr':
          return 'موارد بشرية';
        case 'manager':
          return 'مدير';
        case 'employee':
          return 'موظف';
        default:
          return role;
      }
    } else {
      switch (role) {
        case 'super_admin':
          return 'Super Admin';
        case 'admin':
          return 'Admin';
        case 'hr':
          return 'HR';
        case 'manager':
          return 'Manager';
        case 'employee':
          return 'Employee';
        default:
          return role;
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return const Color(0xFF9C27B0); // Purple
      case 'admin':
        return const Color(0xFFE91E63); // Pink
      case 'hr':
        return const Color(0xFF2196F3); // Blue
      case 'manager':
        return const Color(0xFF009688); // Teal
      case 'employee':
        return const Color(0xFF607D8B); // Blue Grey
      default:
        return AppColors.textLightColor;
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
