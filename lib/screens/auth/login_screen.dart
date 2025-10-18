import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AuthProvider, AppProvider>(
        builder: (context, authProvider, appProvider, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Add space at top for centering on larger screens
                      SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    const SizedBox(height: AppConstants.largePadding),
                    Text(
                      appProvider.isRTL ? 'مرحباً بك' : 'Welcome Back',
                      style: AppTextStyles.heading1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      appProvider.isRTL
                          ? 'قم بتسجيل الدخول للوصول إلى منصة مجلس التعاون'
                          : 'Sign in to access GCC Connect platform',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.largePadding),
                    CustomTextField(
                      controller: _emailController,
                      label: appProvider.isRTL ? 'البريد الإلكتروني' : 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    CustomTextField(
                      controller: _passwordController,
                      label: appProvider.isRTL ? 'كلمة المرور' : 'Password',
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
                    const SizedBox(height: AppConstants.smallPadding),
                    Align(
                      alignment: appProvider.isRTL
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _showForgotPasswordDialog(context);
                        },
                        child: Text(
                          appProvider.isRTL
                              ? 'نسيت كلمة المرور؟'
                              : 'Forgot Password?',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    if (authProvider.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(AppConstants.smallPadding),
                        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
                        decoration: BoxDecoration(
                          color: AppColors.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          authProvider.errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.errorColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    CustomButton(
                      text: appProvider.isRTL ? 'تسجيل الدخول' : 'Sign In',
                      onPressed: authProvider.isLoading ? null : _signIn,
                      isLoading: authProvider.isLoading,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          appProvider.isRTL
                              ? 'ليس لديك حساب؟ '
                              : "Don't have an account? ",
                          style: AppTextStyles.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/register');
                          },
                          child: Text(
                            appProvider.isRTL ? 'إنشاء حساب' : 'Sign Up',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.largePadding),
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
                    // Add space at bottom for centering on larger screens
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        context.go('/home');
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          appProvider.isRTL ? 'إعادة تعيين كلمة المرور' : 'Reset Password',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appProvider.isRTL
                  ? 'أدخل بريدك الإلكتروني لإرسال رابط إعادة التعيين'
                  : 'Enter your email to receive a password reset link',
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            CustomTextField(
              controller: emailController,
              label: appProvider.isRTL ? 'البريد الإلكتروني' : 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              appProvider.isRTL ? 'إلغاء' : 'Cancel',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.sendPasswordResetEmail(emailController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        appProvider.isRTL
                            ? 'تم إرسال رابط إعادة التعيين'
                            : 'Password reset link sent',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              appProvider.isRTL ? 'إرسال' : 'Send',
            ),
          ),
        ],
      ),
    );
  }
}