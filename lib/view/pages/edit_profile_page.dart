import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../controller/user_controller.dart';
import '../../service/hive_service.dart';

/// Screen 13: Edit Profile Page
/// Allows changing avatar photo (via image_picker), username, and security password.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UserController _userController = UserController.to;
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  final Rx<String?> _selectedPhotoPath = Rx<String?>(null);
  final RxBool _obscurePassword = true.obs;
  final RxBool _obscureConfirm = true.obs;
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    final u = _userController.currentUser;
    _usernameController = TextEditingController(text: u?.username ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _selectedPhotoPath.value = u?.photoPath;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        _selectedPhotoPath.value = image.path;
      }
    } catch (e) {
      Get.snackbar(
        'GALLERY ACCESS ERROR',
        'Could not access image gallery.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surfaceElevated,
        colorText: AppColors.textPrimary,
        borderColor: AppColors.errorRed,
        borderWidth: 1,
      );
    }
  }

  Future<void> _saveChanges() async {
    final currentUsername = _userController.currentUser?.username ?? '';
    final newUsername = _usernameController.text.trim();
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate Username
    if (newUsername.isEmpty) {
      Get.snackbar(
        'VALIDATION ERROR',
        'Username protocol cannot be blank.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surfaceElevated,
        colorText: AppColors.textPrimary,
        borderColor: AppColors.errorRed,
        borderWidth: 1,
      );
      return;
    }

    if (newUsername != currentUsername) {
      // Check unique username in Hive
      if (HiveService.usersBox.containsKey(newUsername)) {
        Get.snackbar(
          'PROTOCOL CONFLICT',
          'Username already registered by another operative.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceElevated,
          colorText: AppColors.textPrimary,
          borderColor: AppColors.errorRed,
          borderWidth: 1,
        );
        return;
      }
    }

    // Validate Password (if provided)
    if (newPassword.isNotEmpty) {
      if (newPassword.length < 6) {
        Get.snackbar(
          'SECURITY WARNING',
          'Password requires a minimum of 6 characters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceElevated,
          colorText: AppColors.textPrimary,
          borderColor: AppColors.errorRed,
          borderWidth: 1,
        );
        return;
      }
      if (newPassword != confirmPassword) {
        Get.snackbar(
          'VERIFICATION FAILED',
          'Password confirmation does not match.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceElevated,
          colorText: AppColors.textPrimary,
          borderColor: AppColors.errorRed,
          borderWidth: 1,
        );
        return;
      }
    }

    _isLoading.value = true;
    try {
      await _userController.updateProfile(
        photoPath: _selectedPhotoPath.value,
        newUsername: newUsername,
        newPassword: newPassword.isNotEmpty ? newPassword : null,
      );

      Get.snackbar(
        'PROFILE CALIBRATED',
        'Operative credentials updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surfaceElevated,
        colorText: AppColors.textPrimary,
        borderColor: AppColors.primary,
        borderWidth: 1,
        duration: const Duration(seconds: 2),
      );

      Get.back();
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 20),
                child: Column(
                  children: [
                    // Avatar Picker Section
                    _buildAvatarSection(),

                    const SizedBox(height: 28),

                    // Input Form Fields
                    _buildFormCard(),

                    const SizedBox(height: 32),

                    // Save Changes CTA
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                tooltip: 'Return to Profile',
              ),
              Expanded(
                child: Text(
                  'EDIT PROFILE',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance spacer
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(height: 1, color: AppColors.borderHairline),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              transform: Matrix4.rotationZ(0.785398),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Obx(() {
      final path = _selectedPhotoPath.value;
      final fileExists = path != null && File(path).existsSync();

      return Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ClipOval(
              child: fileExists
                  ? Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      width: 84,
                      height: 84,
                    )
                  : const Center(
                      child: Icon(
                        Icons.person_outline,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(
              Icons.camera_alt_outlined,
              size: 16,
              color: AppColors.secondary,
            ),
            label: Text(
              'CHANGE PHOTO',
              style: AppTextStyles.cinzel(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username Field
          _buildFieldLabel('OPERATIVE USERNAME'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _usernameController,
            style: AppTextStyles.bodyDefault(color: AppColors.textPrimary),
            decoration: _inputDecoration(
              hint: 'Enter operative codename',
              prefixIcon: Icons.badge_outlined,
            ),
          ),

          const SizedBox(height: 18),

          // New Password Field
          _buildFieldLabel('NEW PASSWORD (OPTIONAL)'),
          const SizedBox(height: 6),
          Obx(
            () => TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword.value,
              style: AppTextStyles.bodyDefault(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                hint: 'Leave blank to preserve current',
                prefixIcon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () =>
                      _obscurePassword.value = !_obscurePassword.value,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Confirm Password Field
          _buildFieldLabel('CONFIRM NEW PASSWORD'),
          const SizedBox(height: 6),
          Obx(
            () => TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm.value,
              style: AppTextStyles.bodyDefault(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                hint: 'Confirm new password',
                prefixIcon: Icons.lock_clock_outlined,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () =>
                      _obscureConfirm.value = !_obscureConfirm.value,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.cinzel(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall(color: AppColors.textMuted),
      prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: AppColors.borderHairline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading.value ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child: _isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'SAVE CHANGES',
                  style: AppTextStyles.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
        ),
      );
    });
  }
}
