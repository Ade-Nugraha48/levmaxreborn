import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../controller/user_controller.dart';
import '../../controller/auth_controller.dart';
import '../widgets/grid_background.dart';

/// Main Shell Page (Placeholder for Phase 3)
/// Provides immediate landing surface after login/register with logout capability.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = UserController.to;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('LEVMAX SYSTEM', style: AppTextStyles.headingMedium()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            tooltip: 'Logout',
            onPressed: () => AuthController.to.logout(),
          ),
        ],
      ),
      body: GridBackground(
        child: Center(
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WELCOME, ${userController.username.toUpperCase()}',
                  style: AppTextStyles.headingLarge(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'RANK: ${userController.rank} · LEVEL ${userController.level}',
                  style: AppTextStyles.telemetryDotGothic(color: AppColors.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'EXP: ${userController.exp} · HP: ${userController.hp}',
                  style: AppTextStyles.captionMeta(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
