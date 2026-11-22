import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Screen 7: Profile & System Protocol Page (Mobile Tab 3)
/// Provides identity status, streak telemetry, and session logout.
/// Full developer console and settings will be completed in Phase 7.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = UserController.to;
    final authController = AuthController.to;

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
                    'PROFILE',
                    style: AppTextStyles.headingMedium(
                      color: AppColors.textPrimary,
                    ).copyWith(letterSpacing: 2.5),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(21),
                child: Obx(() {
                  final user = userController.currentUser;
                  final username = user?.username ?? 'NOVICE';
                  final rank = user?.rank ?? 'Novice';
                  final level = user?.level ?? 1;
                  final streak = user?.streakDays ?? 0;

                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      // Circular Avatar Frame
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E1F25),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_outline,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        username.toUpperCase(),
                        style: AppTextStyles.headingMedium(
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '$rank · LV. $level · ${streak}D STREAK',
                        style: AppTextStyles.telemetryDotGothic(
                          fontSize: 13,
                          color: AppColors.highlightYellow,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Logout Session Button (Ghost / Outline button)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => authController.logout(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF33343A),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            backgroundColor: const Color(0xFF0D1018),
                          ),
                          child: Text(
                            'LOGOUT SESSION',
                            style: AppTextStyles.buttonCinzel(
                              color: AppColors.errorRed,
                            ).copyWith(letterSpacing: 2.0),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
