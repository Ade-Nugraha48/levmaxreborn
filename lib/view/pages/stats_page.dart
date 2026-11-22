import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Screen 5 & 6: Stats & History Page (Mobile Tab 2)
/// Placeholder for Phase 6 implementation (Radar Chart & Growth Trajectory).
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 21),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF1E2538),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'STATS',
                    style: AppTextStyles.headingMedium(
                      color: AppColors.textPrimary,
                    ).copyWith(letterSpacing: 2.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.query_stats_outlined,
                      color: AppColors.secondary,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SYSTEM ATTRIBUTES',
                      style: AppTextStyles.headingSmall(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PHASE 6 MODULE STANDBY',
                      style: AppTextStyles.labelMonoSmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
