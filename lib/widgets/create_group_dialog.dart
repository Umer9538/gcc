import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/app_constants.dart';
import '../services/messaging_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class CreateGroupDialog extends StatefulWidget {
  final UserModel currentUser;

  const CreateGroupDialog({
    super.key,
    required this.currentUser,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  final MessagingService _messagingService = MessagingService();
  final UserService _userService = UserService();

  List<UserModel> _availableUsers = [];
  List<UserModel> _filteredUsers = [];
  List<UserModel> _selectedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAllUsersExcept(widget.currentUser.id);
      setState(() {
        _availableUsers = users;
        _filteredUsers = users;
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _availableUsers.where((user) {
        return user.fullName.toLowerCase().contains(query) ||
            user.department.toLowerCase().contains(query) ||
            user.position.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isRTL = appProvider.isRTL;

        return AlertDialog(
          title: Text(isRTL ? 'إنشاء مجموعة جديدة' : 'Create New Group'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Group Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'اسم المجموعة *' : 'Group Name *',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isRTL ? 'مطلوب اسم المجموعة' : 'Group name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Group Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'وصف المجموعة' : 'Group Description',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Selected Members
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isRTL ? 'الأعضاء المختارون' : 'Selected Members'} (${_selectedUsers.length})',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedUsers.isEmpty)
                          Text(
                            isRTL ? 'لم يتم اختيار أعضاء' : 'No members selected',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryColor,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _selectedUsers.map((user) {
                              return Chip(
                                avatar: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                                  child: Text(
                                    _getInitials(user.fullName),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                                label: Text(user.fullName),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedUsers.remove(user);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Member Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: isRTL ? 'البحث عن الأعضاء...' : 'Search members...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Available Members List
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Text(
                                isRTL ? 'لا يوجد مستخدمون' : 'No users found',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondaryColor,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final isSelected = _selectedUsers.contains(user);

                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedUsers.add(user);
                                      } else {
                                        _selectedUsers.remove(user);
                                      }
                                    });
                                  },
                                  title: Text(user.fullName),
                                  subtitle: Text('${user.position} • ${user.department}'),
                                  secondary: CircleAvatar(
                                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                                    backgroundImage: user.profileImageUrl?.isNotEmpty == true
                                        ? NetworkImage(user.profileImageUrl!)
                                        : null,
                                    child: user.profileImageUrl?.isEmpty != false
                                        ? Text(
                                            _getInitials(user.fullName),
                                            style: const TextStyle(fontSize: 12),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(isRTL ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _createGroup,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isRTL ? 'إنشاء' : 'Create'),
            ),
          ],
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUsers.isEmpty) {
      final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRTL ? 'يجب اختيار عضو واحد على الأقل' : 'Please select at least one member',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create participants list including the current user
      final participants = [widget.currentUser.id, ..._selectedUsers.map((u) => u.id)];

      final groupId = await _messagingService.createGroupConversation(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        participants: participants,
        createdBy: widget.currentUser.id,
      );

      if (mounted) {
        Navigator.pop(context, groupId); // Return the group ID
      }
    } catch (e) {
      if (mounted) {
        final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL ? 'فشل في إنشاء المجموعة' : 'Failed to create group',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}