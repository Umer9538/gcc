import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedDepartment = 'All';
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'department', 'position'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isRTL = appProvider.isRTL;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(
              isRTL ? 'دليل الموظفين' : 'Employee Directory',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  _showFilterBottomSheet(context, isRTL);
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isRTL ? 'البحث عن موظف...' : 'Search employees...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                // Department filter chips
                FutureBuilder<List<String>>(
                  future: _userService.getDepartments(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final departments = ['All', ...snapshot.data!];

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: departments.map((dept) {
                          final isSelected = _selectedDepartment == dept;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(dept == 'All' ? (isRTL ? 'الكل' : 'All') : dept),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedDepartment = dept;
                                });
                              },
                              selectedColor: AppColors.primaryColor.withOpacity(0.2),
                              checkmarkColor: AppColors.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primaryColor : AppColors.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                // Employee list
                Expanded(
                  child: StreamBuilder<List<UserModel>>(
                    stream: _userService.getAllUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState(isRTL);
                      }

                      var users = snapshot.data!;

                      // Apply filters
                      if (_selectedDepartment != 'All') {
                        users = users.where((user) => user.department == _selectedDepartment).toList();
                      }

                      if (_searchQuery.isNotEmpty) {
                        users = users.where((user) {
                          return user.fullName.toLowerCase().contains(_searchQuery) ||
                                 user.email.toLowerCase().contains(_searchQuery) ||
                                 user.position.toLowerCase().contains(_searchQuery) ||
                                 user.department.toLowerCase().contains(_searchQuery);
                        }).toList();
                      }

                      // Sort users
                      users.sort((a, b) {
                        switch (_sortBy) {
                          case 'department':
                            return a.department.compareTo(b.department);
                          case 'position':
                            return a.position.compareTo(b.position);
                          case 'name':
                          default:
                            return a.fullName.compareTo(b.fullName);
                        }
                      });

                      if (users.isEmpty) {
                        return _buildEmptyState(isRTL, isFiltered: true);
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                            child: ListTile(
                              leading: CircleAvatar(
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
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                user.fullName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.position,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  Text(
                                    user.department,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  if (user.roles.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      children: user.roles.take(2).map((role) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            role,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.phone, size: 20),
                                    onPressed: () => _makePhoneCall(user.phoneNumber),
                                    color: AppColors.gentleGreen,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.email, size: 20),
                                    onPressed: () => _sendEmail(user.email),
                                    color: AppColors.primaryColor,
                                  ),
                                ],
                              ),
                              onTap: () => _showUserDetails(context, user, isRTL),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isRTL, {bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textLightColor,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            isFiltered
                ? (isRTL ? 'لا توجد نتائج' : 'No results found')
                : (isRTL ? 'لا يوجد موظفون' : 'No employees found'),
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              isRTL ? 'جرب البحث بكلمات مختلفة' : 'Try different search terms',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone call to $phoneNumber'),
          ),
        );
      }
    }
  }

  void _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Hello from GCC Connect',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email to $email'),
          ),
        );
      }
    }
  }

  void _showUserDetails(BuildContext context, UserModel user, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
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
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(user.fullName),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                Icons.work_outline,
                isRTL ? 'المنصب' : 'Position',
                user.position,
              ),
              _buildDetailRow(
                Icons.business_outlined,
                isRTL ? 'القسم' : 'Department',
                user.department,
              ),
              _buildDetailRow(
                Icons.email_outlined,
                isRTL ? 'البريد الإلكتروني' : 'Email',
                user.email,
              ),
              _buildDetailRow(
                Icons.phone_outlined,
                isRTL ? 'رقم الهاتف' : 'Phone',
                user.phoneNumber,
              ),
              if (user.roles.isNotEmpty)
                _buildDetailRow(
                  Icons.admin_panel_settings_outlined,
                  isRTL ? 'الأدوار' : 'Roles',
                  user.roles.join(', '),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إغلاق' : 'Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sendEmail(user.email);
            },
            icon: const Icon(Icons.email),
            label: Text(isRTL ? 'إرسال إيميل' : 'Send Email'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, bool isRTL) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRTL ? 'تصفية النتائج' : 'Filter & Sort',
                      style: AppTextStyles.heading3,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                Text(
                  isRTL ? 'ترتيب حسب' : 'Sort by',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),

                RadioListTile<String>(
                  title: Text(isRTL ? 'الاسم (أ-ي)' : 'Name (A-Z)'),
                  value: 'name',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setModalState(() {
                      _sortBy = value!;
                    });
                    setState(() {});
                  },
                ),
                RadioListTile<String>(
                  title: Text(isRTL ? 'القسم' : 'Department'),
                  value: 'department',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setModalState(() {
                      _sortBy = value!;
                    });
                    setState(() {});
                  },
                ),
                RadioListTile<String>(
                  title: Text(isRTL ? 'المنصب' : 'Position'),
                  value: 'position',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setModalState(() {
                      _sortBy = value!;
                    });
                    setState(() {});
                  },
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(isRTL ? 'تطبيق' : 'Apply'),
                  ),
                ),

                const SizedBox(height: AppConstants.smallPadding),
              ],
            ),
          ),
        );
      },
    );
  }
}