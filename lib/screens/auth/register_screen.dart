import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();

  String _selectedDepartment = 'Information Technology';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AuthProvider, AppProvider>(
        builder: (context, authProvider, appProvider, child) {
          final isRTL = appProvider.isRTL;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConstants.largePadding),

                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/logo_circle.png',
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: AppConstants.largePadding),

                    Text(
                      isRTL ? 'إنشاء حساب جديد' : 'Create Account',
                      style: AppTextStyles.heading1,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppConstants.smallPadding),

                    Text(
                      isRTL
                          ? 'املأ النموذج للانضمام إلى منصة مجلس التعاون'
                          : 'Fill the form to join GCC Connect platform',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppConstants.largePadding),

                    // Personal Information
                    Text(
                      isRTL ? 'المعلومات الشخصية' : 'Personal Information',
                      style: AppTextStyles.heading3,
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            label: isRTL ? 'الاسم الأول' : 'First Name',
                            prefixIcon: Icons.person_outline,
                            validator: (value) => Validators.validateName(value),
                          ),
                        ),
                        const SizedBox(width: AppConstants.defaultPadding),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            label: isRTL ? 'الاسم الأخير' : 'Last Name',
                            prefixIcon: Icons.person_outline,
                            validator: (value) => Validators.validateName(value),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    CustomTextField(
                      controller: _emailController,
                      label: isRTL ? 'البريد الإلكتروني' : 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: Validators.validateEmail,
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    CustomTextField(
                      controller: _phoneController,
                      label: isRTL ? 'رقم الهاتف' : 'Phone Number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: Validators.validatePhoneNumber,
                    ),

                    const SizedBox(height: AppConstants.largePadding),

                    // Work Information
                    Text(
                      isRTL ? 'معلومات العمل' : 'Work Information',
                      style: AppTextStyles.heading3,
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    // Department Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: InputDecoration(
                        labelText: isRTL ? 'القسم' : 'Department',
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceColor,
                      ),
                      items: AppConstants.departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(
                            isRTL ? (AppConstants.departmentTranslations[dept] ?? dept) : dept,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartment = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isRTL ? 'الرجاء اختيار القسم' : 'Please select a department';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    CustomTextField(
                      controller: _positionController,
                      label: isRTL ? 'المنصب' : 'Position',
                      prefixIcon: Icons.work_outline,
                      validator: (value) => Validators.validateRequired(value, isRTL ? 'المنصب' : 'Position'),
                    ),

                    const SizedBox(height: AppConstants.largePadding),

                    // Security Information
                    Text(
                      isRTL ? 'معلومات الأمان' : 'Security Information',
                      style: AppTextStyles.heading3,
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    CustomTextField(
                      controller: _passwordController,
                      label: isRTL ? 'كلمة المرور' : 'Password',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: Validators.validatePassword,
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: isRTL ? 'تأكيد كلمة المرور' : 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: Icons.lock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) => Validators.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),

                    const SizedBox(height: AppConstants.largePadding),

                    // Error Message
                    if (authProvider.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(AppConstants.smallPadding),
                        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
                        decoration: BoxDecoration(
                          color: AppColors.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          authProvider.errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.errorColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Register Button
                    CustomButton(
                      text: isRTL ? 'إنشاء حساب' : 'Create Account',
                      onPressed: authProvider.isLoading ? null : _signUp,
                      isLoading: authProvider.isLoading,
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isRTL ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ',
                          style: AppTextStyles.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          child: Text(
                            isRTL ? 'تسجيل الدخول' : 'Sign In',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.largePadding),

                    // Language Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            appProvider.changeLanguage('en');
                          },
                          icon: const Text('EN'),
                          color: appProvider.locale.languageCode == 'en'
                              ? AppColors.primaryColor
                              : AppColors.textSecondaryColor,
                        ),
                        const Text(' | '),
                        IconButton(
                          onPressed: () {
                            appProvider.changeLanguage('ar');
                          },
                          icon: const Text('العربية'),
                          color: appProvider.locale.languageCode == 'ar'
                              ? AppColors.primaryColor
                              : AppColors.textSecondaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        department: _selectedDepartment,
        position: _positionController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (success && mounted) {
        context.go('/home');
      }
    }
  }
}