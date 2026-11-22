import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../service/session_service.dart';
import '../../service/hive_service.dart';
import '../../controller/user_controller.dart';
import '../../routes/app_routes.dart';
import '../widgets/grid_background.dart';
import '../widgets/gothic_divider.dart';

/// Splash Page - Checks Session & Auto-login
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    await Future.delayed(const Duration(milliseconds: 900));

    final isLoggedIn = SessionService.isLoggedIn;
    final activeUsername = SessionService.activeUsername;

    if (isLoggedIn && activeUsername.isNotEmpty) {
      final user = HiveService.usersBox.get(activeUsername);
      if (user != null) {
        UserController.to.loadUser(activeUsername);
        Get.offAllNamed(AppRoutes.main);
        return;
      } else {
        await SessionService.clearSession();
      }
    }

    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GridBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Monolithic Wordmark
              Text(
                'LEVMAX',
                style: AppTextStyles.displayHero(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const GothicDivider(width: 180),
              const SizedBox(height: 13),
              Text(
                'SYSTEM INITIALIZING',
                style: AppTextStyles.labelMonoSm(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
