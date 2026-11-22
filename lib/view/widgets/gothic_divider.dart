import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Architectural Gothic Hairline Divider with Neon Pink Diamond Segmenter
/// Conforms to `docs/style.md` and Google Stitch export blueprints.
class GothicDivider extends StatelessWidget {
  final double width;
  final double diamondSize;

  const GothicDivider({
    super.key,
    this.width = 200,
    this.diamondSize = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hairline horizontal divider line
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.borderHairline,
                  AppColors.borderHairline,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Central Neon Pink Diamond Accent
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: diamondSize,
              height: diamondSize,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    blurRadius: 8,
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
