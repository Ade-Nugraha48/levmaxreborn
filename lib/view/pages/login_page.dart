import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../controller/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../widgets/grid_background.dart';
import '../widgets/gothic_divider.dart';

/// Screen 1: Login Page
/// Wordmark LEVMAX, SYSTEM ACCESS + pink diamond divider,
/// Username & Password inputs with eye toggle, CTA Neon Pink ENTER SYSTEM, link CREATE ACCOUNT.
class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GridBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Sanctum (~38.2% Composition)
                    Text(
                      'LEVMAX',
                      style: AppTextStyles.displayHero(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const GothicDivider(width: 192),
                    const SizedBox(height: 8),
                    Text(
                      'SYSTEM ACCESS',
                      style: AppTextStyles.headingSmall(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 34),

                    // Operational Form (~61.8% Console)
                    _buildInputLabel('USERNAME'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller.usernameController,
                      style: AppTextStyles.bodyDefault(),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'unique identifier',
                        hintStyle: AppTextStyles.bodyDefault(color: AppColors.textMuted),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 21),

                    _buildInputLabel('PASSWORD'),
                    const SizedBox(height: 6),
                    Obx(
                      () => TextField(
                        controller: controller.passwordController,
                        obscureText: !controller.isPasswordVisible.value,
                        style: AppTextStyles.bodyDefault(),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: 'cipher key',
                          hintStyle: AppTextStyles.bodyDefault(color: AppColors.textMuted),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: controller.isPasswordVisible.value
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // CTA Neon Pink Button
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value ? null : controller.login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: const Color(0xFF0D0E13),
                            elevation: 0,
                            shadowColor: AppColors.primary.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0D0E13),
                                    ),
                                  ),
                                )
                              : Text(
                                  'ENTER SYSTEM',
                                  style: AppTextStyles.buttonCinzel(
                                    color: const Color(0xFF0D0E13),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Relational Link to Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No account? ',
                          style: AppTextStyles.captionMeta(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            controller.clearInputs();
                            Get.toNamed(AppRoutes.register);
                          },
                          child: Text(
                            'CREATE ACCOUNT',
                            style: AppTextStyles.headingSmall(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppTextStyles.headingSmall(color: AppColors.textSecondary),
      ),
    );
  }
}
