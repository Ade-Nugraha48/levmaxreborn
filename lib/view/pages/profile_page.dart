import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/cardio_controller.dart';
import '../../controller/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../model/achievement_model.dart';
import '../../routes/app_routes.dart';
import '../../service/hive_service.dart';
import '../../service/notification_service.dart';
import '../../service/session_service.dart';
import '../widgets/streak_flame_badge.dart';

/// Screen 7: Profile & System Protocol Page (Mobile Tab 3)
/// Provides operative identity, streak telemetry, Achievements entry,
/// Edit Profile entry, 19:00 Daily Reminder toggle, Collapsible Developer Demo Console,
/// and session logout.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserController _userController = UserController.to;
  final AuthController _authController = AuthController.to;

  final RxBool _isDevControlsExpanded = false.obs;
  final RxBool _isDailyReminderOn = SessionService.dailyReminderEnabled.obs;
  final RxBool _isSkipRestTimerOn = SessionService.skipRestTimer.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
                child: Obx(() {
                  final user = _userController.currentUser;
                  if (user == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final userLogs = HiveService.questLogsBox.values
                      .where((l) => l.username == user.username)
                      .toList();

                  final achievements = AchievementModel.evaluateAll(
                    user: user,
                    logs: userLogs,
                  );

                  final unlockedCount =
                      achievements.where((a) => a.isUnlocked).length;

                  return Column(
                    children: [
                      const SizedBox(height: 8),

                      // 1. Operative Identity Header (Avatar + Username + Level/Streak)
                      _buildIdentitySection(user),

                      const SizedBox(height: 28),

                      // 2. Protocols Menu (Achievements, Edit Profile, Daily Reminder)
                      _buildMenuSection(unlockedCount),

                      const SizedBox(height: 20),

                      // 3. Collapsible Developer Demo Console
                      _buildDeveloperDemoConsole(),

                      const SizedBox(height: 28),

                      // 4. Ghost Logout Action
                      _buildLogoutButton(context),

                      const SizedBox(height: 24),
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

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 21),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PROFILE',
            style: AppTextStyles.cinzel(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 2.5,
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(dynamic user) {
    final photoPath = user.photoPath;
    final hasValidPhoto = photoPath != null &&
        photoPath.isNotEmpty &&
        File(photoPath).existsSync();

    return Column(
      children: [
        // Circular Avatar Frame with Neon Pink Shadow
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: hasValidPhoto
                ? Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  )
                : const Center(
                    child: Icon(
                      Icons.person_outline,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 14),

        // Operative Username
        Text(
          user.username.toUpperCase(),
          style: AppTextStyles.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 2.0,
          ),
        ),

        const SizedBox(height: 6),

        // Status Row: RANK · LV. X · XD STREAK
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${user.rank.toUpperCase()} · LV. ${user.level} · ',
              style: AppTextStyles.dotGothic(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            StreakFlameBadge(streakDays: user.streakDays),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection(int unlockedAchievementsCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Item 01: ACHIEVEMENTS
          _buildMenuItem(
            icon: Icons.military_tech,
            title: 'ACHIEVEMENTS',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.borderHairline, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '${unlockedAchievementsCount.toString().padLeft(2, '0')} / 08',
                style: AppTextStyles.dotGothic(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
            onTap: () => Get.toNamed(AppRoutes.achievements),
          ),

          const Divider(color: AppColors.borderHairline, height: 1),

          // Item 02: EDIT PROFILE
          _buildMenuItem(
            icon: Icons.manage_accounts_outlined,
            title: 'EDIT PROFILE',
            subtitle: 'AVATAR & SECURITY PROTOCOLS',
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: () => Get.toNamed(AppRoutes.editProfile),
          ),

          const Divider(color: AppColors.borderHairline, height: 1),

          // Item 03: DAILY REMINDER (19:00 SCHEDULED ALERTS)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(color: AppColors.borderHairline, width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY REMINDER',
                          style: AppTextStyles.cinzel(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '19:00 SCHEDULED ALERTS',
                          style: AppTextStyles.labelMonoSmall(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Obx(() {
                  return Switch(
                    value: _isDailyReminderOn.value,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.background,
                    onChanged: (val) async {
                      _isDailyReminderOn.value = val;
                      await SessionService.setDailyReminderEnabled(val);
                      if (val) {
                        await NotificationService.scheduleDailyReminder(
                          hour: 19,
                          minute: 0,
                        );
                        Get.snackbar(
                          'REMINDER ACTIVE',
                          'Daily quest reminder armed for 19:00.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.surfaceElevated,
                          colorText: AppColors.textPrimary,
                          borderColor: AppColors.primary,
                          borderWidth: 1,
                        );
                      } else {
                        await NotificationService.cancelDailyReminder();
                        Get.snackbar(
                          'REMINDER STANDBY',
                          'Daily reminder disarmed.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.surfaceElevated,
                          colorText: AppColors.textPrimary,
                          borderColor: AppColors.textSecondary,
                          borderWidth: 1,
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.borderHairline, width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Icon(icon, color: AppColors.secondary, size: 16),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cinzel(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.labelMonoSmall(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  // --- DEVELOPER DEMO CONSOLE ---

  Widget _buildDeveloperDemoConsole() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Accordion Header
          InkWell(
            onTap: () => _isDevControlsExpanded.toggle(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.terminal,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DEVELOPER DEMO CONTROLS',
                        style: AppTextStyles.cinzel(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  Obx(
                    () => Icon(
                      _isDevControlsExpanded.value
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Drawer Content
          Obx(() {
            if (!_isDevControlsExpanded.value) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderHairline, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Row 1: Penalty & Health Simulation (-34 HP & Restore HP)
                  Row(
                    children: [
                      Expanded(
                        child: _buildDevButton(
                          label: '-34 HP (MISSED DAY)',
                          color: AppColors.errorRed,
                          onPressed: () async {
                            final currentHp =
                                _userController.currentUser?.hp ?? 100;
                            await _userController.deductHp(34);
                            final newHp =
                                _userController.currentUser?.hp ?? 100;
                            Get.snackbar(
                              'SIMULATION: MISSED DAY',
                              newHp == 100
                                  ? 'HP reached 0. 3-Day Inactivity Penalty applied & HP restored to 100.'
                                  : 'Missed 1 day protocol. -34 HP deducted ($currentHp -> $newHp HP).',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surfaceElevated,
                              colorText: AppColors.textPrimary,
                              borderColor: AppColors.errorRed,
                              borderWidth: 1,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDevButton(
                          label: 'RESTORE HP (100)',
                          color: AppColors.end,
                          onPressed: () async {
                            await _userController.restoreHp();
                            Get.snackbar(
                              'SIMULATION: HEAL',
                              'HP restored to maximum capacity (100 HP).',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surfaceElevated,
                              colorText: AppColors.textPrimary,
                              borderColor: AppColors.end,
                              borderWidth: 1,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 2: Inactivity Penalty & Stats Boost
                  Row(
                    children: [
                      Expanded(
                        child: _buildDevButton(
                          label: '+3 DAYS PENALTY',
                          color: AppColors.errorRed,
                          onPressed: () async {
                            await _userController.applyThreeDayPenalty();
                            Get.snackbar(
                              'SIMULATION: PENALTY',
                              'Stats dropped 1 strata. HP restored to 100.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surfaceElevated,
                              colorText: AppColors.textPrimary,
                              borderColor: AppColors.errorRed,
                              borderWidth: 1,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDevButton(
                          label: '+50 ALL STATS',
                          color: AppColors.secondary,
                          onPressed: () async {
                            await _userController.addStatsToAll(50);
                            Get.snackbar(
                              'SIMULATION: BOOST',
                              '+50 Points distributed across ALL 6 attributes.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surfaceElevated,
                              colorText: AppColors.textPrimary,
                              borderColor: AppColors.secondary,
                              borderWidth: 1,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 3: EXP Level Up & Cardio Simulation
                  Row(
                    children: [
                      Expanded(
                        child: _buildDevButton(
                          label: '+300 EXP (LEVEL UP)',
                          color: AppColors.primary,
                          onPressed: () async {
                            final res = await _userController.addExp(300);
                            Get.snackbar(
                              res.didLevelUp
                                  ? 'LEVEL UP ASCENSION'
                                  : 'EXP ADDED',
                              '+300 EXP added. New Level: ${res.newLevel}.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surfaceElevated,
                              colorText: AppColors.textPrimary,
                              borderColor: AppColors.primary,
                              borderWidth: 1,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDevButton(
                          label: 'SIMULATE CARDIO +500M',
                          color: AppColors.highlightYellow,
                          onPressed: () {
                            if (Get.isRegistered<CardioController>()) {
                              Get.find<CardioController>()
                                  .simulateAddDistance(meters: 500);
                              Get.snackbar(
                                'CARDIO BOOST',
                                '+500 meters injected to active telemetry.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.surfaceElevated,
                                colorText: AppColors.textPrimary,
                                borderColor: AppColors.highlightYellow,
                                borderWidth: 1,
                              );
                            } else {
                              Get.snackbar(
                                'CARDIO STANDBY',
                                'Navigate to MAP tab to initialize session.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.surfaceElevated,
                                colorText: AppColors.textPrimary,
                                borderColor: AppColors.textSecondary,
                                borderWidth: 1,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 3: Skip Rest Timer Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SKIP REST TIMER (WORKOUT)',
                        style: AppTextStyles.cinzel(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Obx(
                        () => Switch(
                          value: _isSkipRestTimerOn.value,
                          activeThumbColor: AppColors.secondary,
                          activeTrackColor:
                              AppColors.secondary.withValues(alpha: 0.3),
                          inactiveThumbColor: AppColors.textSecondary,
                          inactiveTrackColor: AppColors.background,
                          onChanged: (val) async {
                            _isSkipRestTimerOn.value = val;
                            await SessionService.setSkipRestTimer(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDevButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1),
          backgroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.dotGothic(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF33343A), width: 1),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        icon: const Icon(Icons.logout, size: 16, color: AppColors.errorRed),
        label: Text(
          'LOGOUT SESSION',
          style: AppTextStyles.cinzel(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.errorRed,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderHairline, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          'KONFIRMASI LOGOUT',
          style: AppTextStyles.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.errorRed,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari sesi sistem LEVMAX?',
          style: AppTextStyles.bodySmall(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'BATAL',
              style: AppTextStyles.button(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _authController.logout();
            },
            child: Text(
              'LOGOUT',
              style: AppTextStyles.button(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
