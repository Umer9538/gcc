import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/app_constants.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _positionController;
  late TextEditingController _departmentController;

  // State variables
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _selectedImagePath;
  String? _uploadedImageUrl;

  // Available departments and positions
  final List<String> _departments = [
    'Engineering',
    'Human Resources',
    'Finance',
    'Marketing',
    'Sales',
    'Operations',
    'Legal',
    'IT Support',
    'Administration',
    'Quality Assurance',
  ];

  final List<String> _positions = [
    'Manager',
    'Senior Developer',
    'Developer',
    'Junior Developer',
    'Team Lead',
    'Project Manager',
    'Business Analyst',
    'Designer',
    'QA Engineer',
    'Administrator',
    'Coordinator',
    'Specialist',
    'Associate',
    'Executive',
    'Director',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _positionController = TextEditingController(text: widget.user.position);
    _departmentController = TextEditingController(text: widget.user.department);
    _uploadedImageUrl = widget.user.profileImageUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
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
              isRTL ? 'تعديل الملف الشخصي' : 'Edit Profile',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: Text(
                  isRTL ? 'حفظ' : 'Save',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  // Profile Image Section
                  _buildProfileImageSection(isRTL),
                  const SizedBox(height: AppConstants.largePadding),

                  // Personal Information
                  _buildSectionHeader(
                    isRTL ? 'المعلومات الشخصية' : 'Personal Information',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // First Name & Last Name
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _firstNameController,
                          label: isRTL ? 'الاسم الأول' : 'First Name',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return isRTL ? 'مطلوب الاسم الأول' : 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppConstants.defaultPadding),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _lastNameController,
                          label: isRTL ? 'اسم العائلة' : 'Last Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return isRTL ? 'مطلوب اسم العائلة' : 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Phone Number
                  _buildTextFormField(
                    controller: _phoneController,
                    label: isRTL ? 'رقم الهاتف' : 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isRTL ? 'مطلوب رقم الهاتف' : 'Phone number is required';
                      }
                      if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value)) {
                        return isRTL ? 'رقم هاتف غير صحيح' : 'Invalid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // Work Information
                  _buildSectionHeader(
                    isRTL ? 'معلومات العمل' : 'Work Information',
                    Icons.work_outline,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Position
                  _buildDropdownField(
                    controller: _positionController,
                    label: isRTL ? 'المنصب' : 'Position',
                    icon: Icons.badge_outlined,
                    items: _positions,
                    isRTL: isRTL,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isRTL ? 'مطلوب المنصب' : 'Position is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Department
                  _buildDropdownField(
                    controller: _departmentController,
                    label: isRTL ? 'القسم' : 'Department',
                    icon: Icons.business_outlined,
                    items: _departments,
                    isRTL: isRTL,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isRTL ? 'مطلوب القسم' : 'Department is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // Account Information (Read-only)
                  _buildSectionHeader(
                    isRTL ? 'معلومات الحساب' : 'Account Information',
                    Icons.account_circle_outlined,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  _buildReadOnlyField(
                    label: isRTL ? 'البريد الإلكتروني' : 'Email',
                    value: widget.user.email,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  _buildReadOnlyField(
                    label: isRTL ? 'الأدوار' : 'Roles',
                    value: widget.user.roles.join(', '),
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isRTL ? 'حفظ التغييرات' : 'Save Changes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImageSection(bool isRTL) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryColor,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                backgroundImage: _selectedImagePath != null
                    ? FileImage(File(_selectedImagePath!))
                    : (_uploadedImageUrl?.isNotEmpty == true
                        ? NetworkImage(_uploadedImageUrl!)
                        : null),
                child: (_selectedImagePath == null && _uploadedImageUrl?.isEmpty != false)
                    ? Text(
                        _getInitials(widget.user.fullName),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isUploadingImage ? null : _showImagePickerOptions,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Text(
          isRTL ? 'اضغط لتغيير الصورة' : 'Tap to change photo',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.borderColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surfaceColor,
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> items,
    required bool isRTL,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(controller.text.trim()) && controller.text.trim().isNotEmpty
          ? controller.text.trim()
          : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surfaceColor,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          controller.text = value;
        }
      },
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        filled: true,
        fillColor: AppColors.surfaceColor.withValues(alpha: 0.5),
        labelStyle: TextStyle(color: AppColors.textSecondaryColor),
      ),
      style: TextStyle(color: AppColors.textSecondaryColor),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _showImagePickerOptions() {
    final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(isRTL ? 'اختيار من المعرض' : 'Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(isRTL ? 'التقاط صورة' : 'Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_uploadedImageUrl?.isNotEmpty == true || _selectedImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.errorColor),
                title: Text(
                  isRTL ? 'حذف الصورة' : 'Remove Photo',
                  style: const TextStyle(color: AppColors.errorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL ? 'فشل في اختيار الصورة' : 'Failed to pick image',
            ),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
      _uploadedImageUrl = null;
    });
  }

  Future<String?> _uploadImage(String imagePath) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final file = File(imagePath);
      final fileName = 'profile_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('profile_images/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      if (mounted) {
        final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL ? 'فشل في رفع الصورة' : 'Failed to upload image',
            ),
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? finalImageUrl = _uploadedImageUrl;

      // Upload new image if selected
      if (_selectedImagePath != null) {
        finalImageUrl = await _uploadImage(_selectedImagePath!);
        if (finalImageUrl == null) {
          // Upload failed, don't proceed
          return;
        }
      }

      // Prepare update data
      final updates = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'position': _positionController.text.trim(),
        'department': _departmentController.text.trim(),
        'profileImageUrl': finalImageUrl,
      };

      // Update user profile
      await _userService.updateUserProfile(widget.user.id, updates);

      // Update AuthProvider with new user data
      if (mounted) {
        final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
        final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;
        await authProvider.refreshCurrentUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRTL ? 'تم حفظ التغييرات بنجاح' : 'Profile updated successfully',
              ),
              backgroundColor: AppColors.successColor,
            ),
          );

          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL ? 'فشل في حفظ التغييرات' : 'Failed to update profile',
            ),
            backgroundColor: AppColors.errorColor,
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