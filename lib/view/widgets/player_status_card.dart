import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/stat_calculator.dart';
import 'gothic_divider.dart';

/// Player Status HUD Card (Upper Focus: 38.2% of Golden Ratio)
/// Conforms strictly to Stitch `05_home.html` and `docs/design_blueprint.md`.
class PlayerStatusCard extends StatelessWidget {
  const PlayerStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = UserController.to;

    return Obx(() {
      final user = userController.currentUser;
      final username = user?.username ?? 'NOVICE';
      final rank = user?.rank ?? 'Novice';
      final level = user?.level ?? 1;
      final hp = user?.hp ?? 100;
      final exp = user?.exp ?? 0;
      final targetExp = StatCalculator.targetExpForLevel(level);
      final double hpPercent = (hp / 100).clamp(0.0, 1.0);
      final double expPercent =
          targetExp > 0 ? (exp / targetExp).clamp(0.0, 1.0) : 0.0;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(35, 18, 55, 0.72),
              Color.fromRGBO(18, 14, 26, 0.90),
            ],
          ),
          border: Border.all(
            color: const Color.fromRGBO(168, 85, 247, 0.30),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(168, 85, 247, 0.15),
              blurRadius: 24,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // Top edge hairline accent line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Row: Avatar Sigil, Username & Rank, Level
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Cyberpunk Avatar Frame with Corner Notches
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1F25),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Top-Right & Bottom-Left Pink Corner Accents
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  color: AppColors.primary,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  color: AppColors.primary,
                                ),
                              ),
                              // Outlined Eagle Sigil
                              const Icon(
                                Icons.shield_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 13),
                        // Username, Rank Badge, and Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    username.toUpperCase(),
                                    style: AppTextStyles.bodyStrong(
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                          168, 85, 247, 0.20),
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: const Color.fromRGBO(
                                            168, 85, 247, 0.50),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      rank.toUpperCase(),
                                      style: AppTextStyles.labelMonoSmall(
                                        color: const Color(0xFFC084FC),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SANCTUM GUARDIAN',
                                style: AppTextStyles.labelMonoSmall(
                                  color: AppColors.textSecondary,
                                ).copyWith(
                                  letterSpacing: 2.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Class Level Telemetry
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'CLASS',
                              style: AppTextStyles.labelMonoSmall(
                                color: AppColors.textSecondary,
                              ).copyWith(fontSize: 9, letterSpacing: 2.0),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'LV. $level',
                              style: AppTextStyles.telemetryDotGothic(
                                fontSize: 18,
                                color: AppColors.highlightYellow,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Divider with Pink Diamond
                    const SizedBox(height: 12),
                    const GothicDivider(),
                    const SizedBox(height: 12),

                    // HP Bar Section
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'HP',
                              style: AppTextStyles.labelMonoSmall(
                                color: AppColors.primary,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            RichText(
                              text: TextSpan(
                                style: AppTextStyles.telemetryDotGothic(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(text: '$hp '),
                                  const TextSpan(
                                    text: '/ 100',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF292A2F),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: hpPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // EXP Bar Section
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'EXP',
                              style: AppTextStyles.labelMonoSmall(
                                color: AppColors.secondary,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            RichText(
                              text: TextSpan(
                                style: AppTextStyles.telemetryDotGothic(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                                children: [
                                  TextSpan(text: '$exp '),
                                  TextSpan(
                                    text: '/ $targetExp',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF292A2F),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: expPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.secondary.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
