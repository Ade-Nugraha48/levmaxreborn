import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions based on Golden Ratio Scale (1.618)
/// As defined in `docs/style.md`:
/// 1. Cinzel (Serif Headings) - Titles, Ranks, CTA buttons (Uppercase with letterSpacing 1.5 - 2.5)
/// 2. DotGothic16 (Gaming Telemetry & Numbers) - Level, quest ratio, timer, repetisi, points
/// 3. Inter (Body & Utility) - Form input, guide description, small labels
class AppTextStyles {
  AppTextStyles._();

  // Cinzel - Headings & Hero
  static TextStyle displayHero({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cinzel(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        color: color,
      );

  static TextStyle headingLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cinzel(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
        color: color,
      );

  static TextStyle headingMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        color: color,
      );

  static TextStyle headingSmall({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: color,
      );

  static TextStyle buttonCinzel({Color color = AppColors.textPrimary}) =>
      GoogleFonts.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: color,
      );

  // DotGothic16 - Telemetry & Numbers (Tabular Figures)
  static TextStyle telemetryDotGothic({
    double fontSize = 16,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.dotGothic16(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle timerDisplay({Color color = AppColors.primary}) =>
      GoogleFonts.dotGothic16(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle metricLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.dotGothic16(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle metricMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.dotGothic16(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle metricSmall({Color color = AppColors.textPrimary}) =>
      GoogleFonts.dotGothic16(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Inter - Body & Utility
  static TextStyle bodyDefault({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  static TextStyle bodyStrong({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  static TextStyle captionMeta({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        color: color,
      );

  static TextStyle labelMonoSm({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      );
}
