import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Screen 7: Streak Flame Badge
/// Renders a dynamic tiered flame icon reflecting login streak tiers:
/// - 0 days: Muted grey
/// - 1-6 days: Yellow (#FACC15)
/// - 7-13 days: Orange (#F97316)
/// - 14-29 days: Red (#EF4444)
/// - >= 30 days: Purple (#A855F7)
class StreakFlameBadge extends StatelessWidget {
  final int streakDays;
  final double iconSize;
  final double fontSize;
  final bool showText;

  const StreakFlameBadge({
    super.key,
    required this.streakDays,
    this.iconSize = 16,
    this.fontSize = 13,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getFlameColor(streakDays);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.local_fire_department,
          size: iconSize,
          color: color,
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            '${streakDays}D STREAK',
            style: AppTextStyles.dotGothic(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  static Color _getFlameColor(int days) {
    if (days >= 30) return AppColors.streakFlamePurple;
    if (days >= 14) return AppColors.streakFlameRed;
    if (days >= 7) return AppColors.streakFlameOrange;
    if (days >= 1) return AppColors.streakFlameYellow;
    return AppColors.textSecondary;
  }
}
