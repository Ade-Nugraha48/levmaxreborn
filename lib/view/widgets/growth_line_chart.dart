import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Screen 6: Line Chart displaying user's growth trajectory over time.
/// Renders safely even on Day 1 (0 stats / 1 data point).
class GrowthLineChart extends StatelessWidget {
  final List<MapEntry<String, int>> snapshots;

  const GrowthLineChart({
    super.key,
    required this.snapshots,
  });

  @override
  Widget build(BuildContext context) {
    // Generate FlSpots safely
    final List<FlSpot> spots = [];
    final List<String> dateLabels = [];

    if (snapshots.isEmpty) {
      spots.add(const FlSpot(0, 0));
      spots.add(const FlSpot(1, 0));
      dateLabels.addAll(['INIT', 'NOW']);
    } else if (snapshots.length == 1) {
      final val = snapshots.first.value.toDouble();
      spots.add(FlSpot(0, val));
      spots.add(FlSpot(1, val));
      dateLabels.addAll(['DAY 01', 'NOW']);
    } else {
      for (int i = 0; i < snapshots.length; i++) {
        spots.add(FlSpot(i.toDouble(), snapshots[i].value.toDouble()));
        // Shorten date (e.g. "2026-11-22" -> "22 NOV")
        dateLabels.add(_formatShortDate(snapshots[i].key));
      }
    }

    final maxYVal = spots.map((s) => s.y).reduce(max);
    final calculatedMaxY = max(100.0, maxYVal * 1.25);
    final maxX = (spots.length - 1).toDouble();

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: calculatedMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: calculatedMaxY / 3,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: AppColors.borderHairline,
              strokeWidth: 0.75,
              dashArray: [2, 4],
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: AppColors.borderHairline, width: 1),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: max(1, (maxX / 3).floorToDouble()),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dateLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dateLabels[index],
                        style: AppTextStyles.dotGothic(
                          fontSize: 9,
                          color: index == dateLabels.length - 1
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((barSpot) {
                  return LineTooltipItem(
                    '${barSpot.y.toInt()} PTS',
                    AppTextStyles.dotGothic(
                      fontSize: 11,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false, // Razor precision cyberpunk line
              color: AppColors.secondary,
              barWidth: 1.75,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.22),
                    AppColors.secondary.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isLast = index == spots.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 4.0 : 2.5,
                    color: isLast ? AppColors.secondary : AppColors.primary,
                    strokeWidth: 1.0,
                    strokeColor: AppColors.background,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatShortDate(String dateStr) {
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
}
