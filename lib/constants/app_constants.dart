import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'GCC Connect';
  static const String appVersion = '1.0.0';

  static const List<String> supportedLanguages = ['en', 'ar'];

  static const List<String> departments = [
    'Administration',
    'Finance',
    'Human Resources',
    'Information Technology',
    'Operations',
    'Legal Affairs',
    'Public Relations',
    'Strategic Planning',
  ];

  static const List<String> roles = [
    'admin',
    'manager',
    'employee',
    'hr',
    'it_support',
  ];

  static const Map<String, String> departmentTranslations = {
    'Administration': 'الإدارة',
    'Finance': 'المالية',
    'Human Resources': 'الموارد البشرية',
    'Information Technology': 'تقنية المعلومات',
    'Operations': 'العمليات',
    'Legal Affairs': 'الشؤون القانونية',
    'Public Relations': 'العلاقات العامة',
    'Strategic Planning': 'التخطيط الاستراتيجي',
  };

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Subtle border radius for professional, clean look
  static const double defaultBorderRadius = 8.0;
  static const double smallBorderRadius = 4.0;
  static const double largeBorderRadius = 12.0;

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}

class AppColors {
  // GCC Official Colors (Blue - Primary Brand/Links)
  static const Color primaryColor = Color(0xFF1E5A9E);
  static const Color primaryLightColor = Color(0xFF2E7ABD);
  static const Color primaryDarkColor = Color(0xFF154478);

  // Secondary accent colors (Green - Brand touches)
  static const Color secondaryColor = Color(0xFF2D8659);
  static const Color secondaryLightColor = Color(0xFF3AA96F);
  static const Color secondaryDarkColor = Color(0xFF236B47);

  // Professional accent colors (Lighter Blue for variety)
  static const Color accentColor = Color(0xFF4A90E2);
  static const Color accentLightColor = Color(0xFF6BA5E8);
  static const Color accentDarkColor = Color(0xFF357ABD);

  // Clean professional background colors (White/light gray)
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Professional text colors (Black/dark gray)
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF616161);
  static const Color textLightColor = Color(0xFF9E9E9E);

  // Corporate status colors
  static const Color errorColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF059669);
  static const Color infoColor = Color(0xFF0284C7);

  // Clean borders and dividers
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color shadowColor = Color(0x0A000000);

  // Professional gradients (subtle, flat design approach)
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, secondaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Professional accent colors for variety
  static const Color gentleGreen = Color(0xFF2D8659);
  static const Color gentlePurple = Color(0xFF7C3AED);
  static const Color gentleOrange = Color(0xFFF97316);
  static const Color gentlePink = Color(0xFFEC4899);
  static const Color lightGray = Color(0xFFF9FAFB);
  static const Color mediumGray = Color(0xFFE5E7EB);
}

class AppTextStyles {
  // Headings for light backgrounds (dark text)
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryColor,
    letterSpacing: -0.2,
  );

  // Headings for colored backgrounds (white text)
  static const TextStyle heading1White = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2White = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3White = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: -0.2,
  );

  // Body text for light backgrounds (dark text)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimaryColor,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryColor,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLightColor,
    height: 1.4,
  );

  // Body text for colored backgrounds (white text)
  static const TextStyle bodyLargeWhite = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
    height: 1.5,
  );

  static const TextStyle bodyMediumWhite = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
    height: 1.5,
  );

  static const TextStyle bodySmallWhite = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white60,
    height: 1.4,
  );

  // Button text (white on colored backgrounds)
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonTextLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // Caption and labels
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLightColor,
    height: 1.3,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondaryColor,
    height: 1.3,
  );

  // Link text (primary blue color)
  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
    decoration: TextDecoration.underline,
  );

  static const TextStyle linkLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
    decoration: TextDecoration.underline,
  );

  // Error and success messages
  static const TextStyle errorText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.errorColor,
  );

  static const TextStyle successText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.successColor,
  );

  static const TextStyle warningText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.warningColor,
  );
}