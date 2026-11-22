import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../model/user_model.dart';

/// Screen 5: Hexagonal Radar Chart displaying the 6 Core Attributes
/// (STR, END, SPD, INT, WIL, APP) with dynamic limit-break scaling.
class StatRadarChart extends StatelessWidget {
  final UserModel user;

  const StatRadarChart({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final statValues = [
      user.strength.toDouble(),
      user.endurance.toDouble(),
      user.speed.toDouble(),
      user.intelligence.toDouble(),
      user.willpower.toDouble(),
      user.appearance.toDouble(),
    ];

    // Determine safe maximum scale (at least 100 for proper concentric hexagon rings)
    final maxStat = statValues.reduce(max);
    final scaleMax = max(100.0, maxStat * 1.15);

    const labels = ['STR', 'END', 'SPD', 'INT', 'WIL', 'APP'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header / Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HEXAGONAL MATRIX',
                style: AppTextStyles.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 2.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.borderHairline, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'SCALE: 0-${scaleMax.toInt()}',
                  style: AppTextStyles.dotGothic(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Radar Chart Canvas
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                radarBorderData: const BorderSide(
                  color: AppColors.borderHairline,
                  width: 1.5,
                ),
                gridBorderData: const BorderSide(
                  color: AppColors.borderHairline,
                  width: 1,
                ),
                tickBorderData: const BorderSide(
                  color: Color(0xFF151A26),
                  width: 1,
                ),
                tickCount: 3,
                titlePositionPercentageOffset: 0.22,
                titleTextStyle: AppTextStyles.labelMonoSmall(
                  color: AppColors.textSecondary,
                ),
                getTitle: (index, angle) {
                  final label = labels[index % labels.length];
                  final val = statValues[index % statValues.length].toInt();

                  return RadarChartTitle(
                    text: '$label\n$val',
                    angle: 0,
                    positionPercentageOffset: 0.15,
                  );
                },
                dataSets: [
                  // Dataset 0: Outer bounding frame to fix scale and prevent 0-division
                  RadarDataSet(
                    fillColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    entryRadius: 0,
                    dataEntries: List.generate(
                      6,
                      (_) => RadarEntry(value: scaleMax),
                    ),
                  ),
                  // Dataset 1: User's Actual Stat Values
                  RadarDataSet(
                    fillColor: AppColors.primary.withValues(alpha: 0.22),
                    borderColor: AppColors.primary,
                    borderWidth: 1.75,
                    entryRadius: 3,
                    dataEntries: statValues
                        .map((v) => RadarEntry(value: max(0.0, v)))
                        .toList(),
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
