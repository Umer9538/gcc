import 'package:flutter/material.dart';

/// Helper extension for easy navigation with shimmer loading
/// Screens automatically show shimmer loading while data loads
extension NavigationWithLoading on BuildContext {
  /// Navigate to a screen - shimmer loading will show automatically on target screen
  /// Clean, simple navigation without blocking overlays
  Future<T?> navigateWithLoading<T>(
    Widget screen, {
    String? loadingMessage, // Kept for API compatibility but not used
  }) async {
    // Simple, clean navigation - target screen handles its own loading state
    final result = await Navigator.push<T>(
      this,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );

    return result;
  }

  /// Replace current screen
  Future<T?> replaceWithLoading<T>(
    Widget screen, {
    String? loadingMessage, // Kept for API compatibility but not used
  }) async {
    final result = await Navigator.pushReplacement<T, void>(
      this,
      MaterialPageRoute(builder: (context) => screen),
    );

    return result;
  }
}
