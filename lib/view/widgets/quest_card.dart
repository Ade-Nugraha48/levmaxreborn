import 'package:flutter/material.dart';
import '../../controller/quest_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Quest Card Widget for Daily Quests List
/// Strictly implements active-first hierarchy:
/// - Active: Broken-white left stick bar, glowing title, separated colored reward badges.
/// - Done: Sinks to bottom, 45% dimmed opacity, strikethrough, DONE badge, muted reward badges.
/// Conforms to `stitch_exports/05_home.html` and `docs/style.md`.
class QuestCard extends StatelessWidget {
  final QuestItemData quest;
  final VoidCallback onTap;

  const QuestCard({
    super.key,
    required this.quest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDone = quest.isDone;

    final content = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1018),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: const Color(0xFF1E2538),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Left Stick Bar (Broken-White for Active, Muted for Done)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 2,
              child: Container(
                color: isDone ? const Color(0xFF33343A) : AppColors.activeStick,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 14,
                top: 12,
                bottom: 12,
                right: 12,
              ),
              child: Row(
                children: [
                  // Title, Subtitle, and Status Indicators
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                quest.title,
                                style: AppTextStyles.bodyStrong(
                                  color: isDone
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ).copyWith(
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!isDone)
                              // Active Pink Dot
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              // DONE Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1F25),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  'DONE',
                                  style: AppTextStyles.labelMonoSmall(
                                    color: AppColors.textSecondary,
                                  ).copyWith(fontSize: 9),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          quest.subtitle,
                          style: AppTextStyles.captionMeta(
                            color: isDone
                                ? const Color(0xFF4B5563)
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Separated Reward Badges
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: quest.rewardBadges.map((badge) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF1E1F25)
                                : badge.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFF33343A)
                                  : badge.color.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            badge.label,
                            style: AppTextStyles.telemetryDotGothic(
                              fontSize: 9,
                              color: isDone
                                  ? AppColors.textSecondary
                                  : badge.color,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(width: 6),

                  // Right Outlined Chevron
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: isDone
                        ? const Color(0xFF4B5563)
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: isDone
          ? Opacity(
              opacity: 0.45,
              child: content,
            )
          : content,
    );
  }
}
