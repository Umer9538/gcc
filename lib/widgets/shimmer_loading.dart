import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer loading widgets for better UX than CircularProgressIndicator
class ShimmerLoading {
  /// List item shimmer (for meetings, announcements, etc.)
  static Widget listItem({
    required bool isWeb,
    int count = 5,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: isWeb ? 20.0 : 16.0),
        child: _buildShimmerCard(isWeb),
      ),
    );
  }

  /// Card shimmer for grid items
  static Widget gridItem({
    required bool isWeb,
    int count = 6,
    int crossAxisCount = 2,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isWeb ? 20 : 16,
        mainAxisSpacing: isWeb ? 20 : 16,
        childAspectRatio: 1.5,
      ),
      itemCount: count,
      itemBuilder: (context, index) => _buildShimmerCard(isWeb),
    );
  }

  /// Single card shimmer
  static Widget card({required bool isWeb}) {
    return Padding(
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      child: _buildShimmerCard(isWeb),
    );
  }

  /// Compact shimmer for small items
  static Widget compact({
    required bool isWeb,
    int count = 3,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      padding: EdgeInsets.all(isWeb ? 20.0 : 16.0),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildCompactShimmerCard(isWeb),
      ),
    );
  }

  static Widget _buildShimmerCard(bool isWeb) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: isWeb ? 120 : 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: isWeb ? 20 : 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity * 0.7,
                height: isWeb ? 16 : 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity * 0.5,
                height: isWeb ? 16 : 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildCompactShimmerCard(bool isWeb) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: isWeb ? 60 : 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: isWeb ? 40 : 32,
                height: isWeb ? 40 : 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity * 0.6,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity * 0.4,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom shimmer for specific layouts
  static Widget custom({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: child,
    );
  }
}
