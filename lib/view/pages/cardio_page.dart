import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Screen 4: Map / Cardio Tracking Page (Mobile Tab 1)
/// Placeholder for Phase 5 implementation (LBS Tracking & Weather API).
class CardioPage extends StatelessWidget {
  const CardioPage({super.key});

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
                    'MAP',
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
                      Icons.directions_run_outlined,
                      color: AppColors.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CARDIO TELEMETRY',
                      style: AppTextStyles.headingSmall(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PHASE 5 MODULE STANDBY',
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
