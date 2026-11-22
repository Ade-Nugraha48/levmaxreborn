import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../controller/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../widgets/grid_background.dart';
import '../widgets/gothic_divider.dart';

/// Screen 2: Register Page
/// Back arrow, sigil kubus pink, REGISTER, tagline DO YOU HAVE WHAT IT TAKES ?,
/// Username, Password, Confirm Password, Consent Checkbox, CTA Neon Pink REGISTER.
class RegisterPage extends GetView<AuthController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Minimal Top Navigation Bar
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  onPressed: () {
                    controller.clearInputs();
                    Get.back();
                  },
                ),
              ),

              // Scrollable Registration Form
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Cathedral Cube Emblem
                          _buildCathedralSigil(),
                          const SizedBox(height: 13),

                          // Sacred Header Hierarchy
                          Text(
                            'REGISTER',
                            style: AppTextStyles.displayHero(),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const GothicDivider(width: 200),
                          const SizedBox(height: 6),
                          Text(
                            'DO YOU HAVE WHAT IT TAKES ?',
                            style: AppTextStyles.labelMonoSm(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Input 1: USERNAME
                          _buildFieldHeader('USERNAME', 'REQ'),
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
                          const SizedBox(height: 16),

                          // Input 2: PASSWORD
                          _buildFieldHeader('PASSWORD', 'MIN 6'),
                          const SizedBox(height: 6),
                          Obx(
                            () => TextField(
                              controller: controller.passwordController,
                              obscureText: !controller.isPasswordVisible.value,
                              style: AppTextStyles.bodyDefault(),
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                hintText: 'minimum 6 characters',
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
                          const SizedBox(height: 16),

                          // Input 3: CONFIRM PASSWORD
                          _buildFieldHeader('CONFIRM PASSWORD', 'MATCH'),
                          const SizedBox(height: 6),
                          Obx(
                            () => TextField(
                              controller: controller.confirmPasswordController,
                              obscureText: !controller.isConfirmPasswordVisible.value,
                              style: AppTextStyles.bodyDefault(),
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                hintText: 're-enter password',
                                hintStyle: AppTextStyles.bodyDefault(color: AppColors.textMuted),
                                prefixIcon: const Icon(
                                  Icons.lock_reset,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.isConfirmPasswordVisible.value
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: controller.isConfirmPasswordVisible.value
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: controller.toggleConfirmPasswordVisibility,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Protocol Affirmation Consent Checkbox
                          Obx(
                            () => InkWell(
                              onTap: () => controller.toggleConsent(!controller.consentAgreed.value),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: controller.consentAgreed.value,
                                      onChanged: controller.toggleConsent,
                                      activeColor: AppColors.primary,
                                      checkColor: Colors.black,
                                      side: const BorderSide(
                                        color: AppColors.borderHairline,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'I consent to the Sovereign Protocol covenants',
                                        style: AppTextStyles.captionMeta(
                                          color: controller.consentAgreed.value
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 21),

                          // Primary Action Button (REGISTER)
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    controller.isLoading.value ? null : controller.register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: const Color(0xFF0D0E13),
                                  elevation: 0,
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
                                        'REGISTER',
                                        style: AppTextStyles.buttonCinzel(
                                          color: const Color(0xFF0D0E13),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bottom Secondary Anchor
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already registered? ',
                                style: AppTextStyles.captionMeta(color: AppColors.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () {
                                  controller.clearInputs();
                                  Get.offNamed(AppRoutes.login);
                                },
                                child: Text(
                                  'Login',
                                  style: AppTextStyles.headingSmall(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldHeader(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.headingSmall(color: AppColors.textSecondary),
        ),
        Text(
          badge,
          style: AppTextStyles.labelMonoSm(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildCathedralSigil() {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.borderHairline),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
