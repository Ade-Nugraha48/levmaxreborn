import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../controller/user_controller.dart';
import '../../model/achievement_model.dart';
import '../../service/hive_service.dart';

/// Screen 8: Achievements Page (System Honors)
/// Displays summary HUD and the 8 System Achievements
/// (Unlocked, Unlocked Rare with Neon Pink border, and Locked with mini progress bar).
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : Get.put(UserController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Gothic Header
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: Obx(() {
                final user = userController.user.value;
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
                final progressRatio = unlockedCount / 8.0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Summary HUD
                      _buildSummaryHud(unlockedCount, progressRatio),

                      const SizedBox(height: 20),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HONORS DIRECTORY',
                            style: AppTextStyles.cinzel(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: 1.6,
                            ),
                          ),
                          Text(
                            '8 CODEX ENTRIES',
                            style: AppTextStyles.dotGothic(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 2. List of 8 Achievements
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: achievements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final ach = achievements[index];
                          return _buildAchievementCard(ach);
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                );
              }),
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
                  'ACHIEVEMENTS',
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
        // Hairline Gothic Divider with Neon Pink Diamond
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 1,
              color: AppColors.borderHairline,
            ),
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

  Widget _buildSummaryHud(int unlockedCount, double progressRatio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HONORS UNLOCKED',
                style: AppTextStyles.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.6,
                ),
              ),
              Text(
                '${(progressRatio * 100).toInt()}%',
                style: AppTextStyles.dotGothic(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                unlockedCount.toString().padLeft(2, '0'),
                style: AppTextStyles.dotGothic(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                ' / 08',
                style: AppTextStyles.dotGothic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clean Progress Bar
          Container(
            width: double.infinity,
            height: 3,
            color: AppColors.background,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressRatio.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(AchievementModel ach) {
    final isUnlocked = ach.isUnlocked;
    final isRare = ach.isRare;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.surface
            : AppColors.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: isUnlocked
              ? (isRare ? AppColors.primary : AppColors.borderHairline)
              : AppColors.borderHairline.withValues(alpha: 0.5),
          width: isUnlocked && isRare ? 1.25 : 1.0,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isUnlocked && isRare
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sigil Box
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(
                    color: isUnlocked
                        ? (isRare ? AppColors.primary : AppColors.secondary)
                        : AppColors.borderHairline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(
                  isUnlocked
                      ? (isRare ? Icons.flash_on : Icons.military_tech)
                      : Icons.lock_outline,
                  color: isUnlocked
                      ? (isRare ? AppColors.primary : AppColors.secondary)
                      : AppColors.textMuted,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Title, Description, & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ach.title,
                            style: AppTextStyles.cinzel(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        if (isRare) ...[
                          const SizedBox(width: 6),
                          Text(
                            '◆',
                            style: TextStyle(
                              fontSize: 8,
                              color: isUnlocked
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ach.description,
                      style: AppTextStyles.bodySmall(
                        color: isUnlocked
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right Status Tag
              if (isUnlocked)
                Text(
                  _formatDateTag(ach.unlockedDate),
                  style: AppTextStyles.dotGothic(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isRare ? AppColors.primary : AppColors.textSecondary,
                  ),
                )
              else
                Text(
                  _formatProgressRatio(ach),
                  style: AppTextStyles.dotGothic(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),

          // Mini progress bar for locked achievements
          if (!isUnlocked) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 2,
              color: AppColors.background,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ach.progressRatio.clamp(0.0, 1.0),
                child: Container(
                  color: isRare ? AppColors.primary : AppColors.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDateTag(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'ACTIVE';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        const months = [
          'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
          'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
        ];
        final monthIdx = int.tryParse(parts[1]) ?? 1;
        final day = parts[2];
        return '$day ${months[(monthIdx - 1).clamp(0, 11)]}';
      }
    } catch (_) {}
    return dateStr;
  }

  static String _formatProgressRatio(AchievementModel ach) {
    if (ach.targetValue <= 1.0) {
      return 'LOCKED';
    }
    return '${ach.currentProgress.toInt()} / ${ach.targetValue.toInt()}';
  }
}
