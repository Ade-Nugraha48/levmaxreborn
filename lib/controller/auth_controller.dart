import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/user_model.dart';
import '../model/grooming_item_model.dart';
import '../service/hive_service.dart';
import '../service/session_service.dart';
import '../controller/user_controller.dart';
import '../routes/app_routes.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/game_config.dart';
import '../core/utils/date_helper.dart';

/// Authentication Controller managing Login, Register, Session, and Auto-login
class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  // Text Editing Controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Reactive State
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxBool consentAgreed = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onClose() {
    // Keep controllers intact to prevent disposal crashes during route transitions
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void toggleConsent(bool? value) {
    consentAgreed.value = value ?? false;
  }

  void clearInputs() {
    usernameController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    errorMessage.value = '';
    consentAgreed.value = false;
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
  }

  /// Handles Login Flow
  Future<bool> login() async {
    errorMessage.value = '';
    final username = usernameController.text.trim();
    final password = passwordController.text;

    // Cek input gak boleh kosong biar gak buang-buang query ke Hive
    if (username.isEmpty || password.isEmpty) {
      errorMessage.value = 'ENTER CREDENTIALS TO ACCESS SYSTEM';
      _showErrorSnackbar(errorMessage.value);
      return false;
    }

    isLoading.value = true;
    try {
      // Cari data user di database Hive lokal berdasarkan username yang diketik
      final user = HiveService.usersBox.get(username);
      if (user == null || user.password != password) {
        errorMessage.value = 'ACCESS DENIED: INVALID CREDENTIALS';
        _showErrorSnackbar(errorMessage.value);
        return false;
      }

      // Simpan status login ke SharedPreferences biar sesi tetap nyantol pas app ditutup
      await SessionService.setIsLoggedIn(true);
      await SessionService.setActiveUsername(username);

      UserController.to.loadUser(username);
      clearInputs();
      Get.offAllNamed(AppRoutes.main);
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Handles Register Flow with Mandatory Validation:
  /// 1. Unique non-empty username
  /// 2. Password >= 6 characters
  /// 3. Confirm password match
  /// 4. Consent checkbox agreed
  Future<bool> register() async {
    errorMessage.value = '';
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // 1. Username validation - wajib diisi dan gak boleh kembar sama akun yang udah ada
    if (username.isEmpty) {
      errorMessage.value = 'IDENTIFIER CANNOT BE EMPTY';
      _showErrorSnackbar(errorMessage.value);
      return false;
    }

    if (HiveService.usersBox.containsKey(username)) {
      errorMessage.value = 'IDENTIFIER ALREADY REGISTERED IN SYSTEM';
      _showErrorSnackbar(errorMessage.value);
      return false;
    }

    // 2. Password minimal 6 karakter sesuai standar keamanan
    if (password.length < 6) {
      errorMessage.value = 'PASSWORD MUST BE AT LEAST 6 CHARACTERS';
      _showErrorSnackbar(errorMessage.value);
      return false;
    }

    // 3. Konfirmasi password harus sama persis
    if (password != confirmPassword) {
      errorMessage.value = 'CIPHER CONFIRMATION DOES NOT MATCH';
      _showErrorSnackbar(errorMessage.value);
      return false;
    }

    // 4. Syarat ketentuan protokol harus dicentang
    if (!consentAgreed.value) {
      errorMessage.value = 'SOVEREIGN PROTOCOL COVENANTS MUST BE ACCEPTED';
      _showErrorSnackbar(errorMessage.value);
      return false;
    }

    isLoading.value = true;
    try {
      final today = DateHelper.todayString();

      // Bikin objek akun baru UserModel dengan stat awal (level 1, rank Novice)
      final newUser = UserModel(
        username: username,
        password: password,
        level: 1,
        exp: 0,
        hp: 100,
        strength: 0,
        endurance: 0,
        speed: 0,
        intelligence: 0,
        willpower: 0,
        appearance: 0,
        streakDays: 0,
        longestStreak: 0,
        lastActiveDate: today,
        createdAt: DateTime.now(),
        rankHistory: {'Novice': today},
        unlockedAchievements: {'the_awakening': today},
        growthSnapshots: {today: 0},
      );

      // Simpan data akun baru ke Hive usersBox
      await HiveService.usersBox.put(username, newUser);

      // Isi 5 checklist grooming bawaan buat akun baru biar fiturnya langsung ada isi
      for (int i = 0; i < GameConfig.defaultGroomingItems.length; i++) {
        final title = GameConfig.defaultGroomingItems[i];
        final item = GroomingItemModel(
          id: '${username}_$i',
          username: username,
          title: title,
          isChecked: false,
          isDefault: true,
        );
        await HiveService.groomingItemsBox.add(item);
      }

      // Jangan langsung masuk ke home; suruh user buat login manual dulu
      await SessionService.setIsLoggedIn(false);
      await SessionService.setActiveUsername('');

      clearInputs();

      if (!Get.testMode) {
        Get.snackbar(
          'REGISTRATION SUCCESSFUL',
          'Operative identity registered. Enter credentials to log in.',
          backgroundColor: AppColors.surfaceElevated,
          colorText: AppColors.primary,
          borderColor: AppColors.primary,
          borderWidth: 1,
          borderRadius: 4,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(13),
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
        );
      }

      Get.offAllNamed(AppRoutes.login);
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Handles User Logout
  Future<void> logout() async {
    // Hapus sesi di SharedPreferences dan kosongkan user aktif di memory
    await SessionService.clearSession();
    UserController.to.user.value = null;
    clearInputs();
    Get.offAllNamed(AppRoutes.login);
  }

  void _showErrorSnackbar(String message) {
    if (Get.testMode) return;
    Get.snackbar(
      'SYSTEM PROTOCOL ERROR',
      message,
      backgroundColor: AppColors.surfaceElevated,
      colorText: AppColors.primary,
      borderColor: AppColors.primary,
      borderWidth: 1,
      borderRadius: 4,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(13),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error_outline, color: AppColors.primary),
    );
  }
}
