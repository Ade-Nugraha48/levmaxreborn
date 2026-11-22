import 'package:flutter/material.dart';

/// Minimalist Neo-Gothic Cyberpunk Pink Color Palette
/// As defined in `docs/style.md` and `docs/design_blueprint.md`.
class AppColors {
  AppColors._();

  // Base background & surfaces
  static const Color background = Color(0xFF05060A); // Void Black
  static const Color surface = Color(0xFF0D1018); // Obsidian (level 1 card & BottomNav)
  static const Color surfaceElevated = Color(0xFF151A26); // Elevated Slate (input field & active container)

  // Primary & Secondary accents
  static const Color primary = Color(0xFFFF2A85); // Neon Pink - CTA primer, HP bar, rare border
  static const Color secondary = Color(0xFF00D4FF); // Electric Cyan - EXP bar, cadence bar, growth line
  static const Color borderHairline = Color(0xFF1E2538); // 1px border tipis & divider
  static const Color gridOverlay = Color(0x06FFFFFF); // rgba(255, 255, 255, 0.025)

  // Text colors
  static const Color textPrimary = Color(0xFFF3F4F6); // Off-white
  static const Color textSecondary = Color(0xFF7A8499); // Slate grey (dimmed items)
  static const Color textMuted = Color(0xFF4B5563);

  // Status & Highlights
  static const Color activeStick = Color(0xFFE5E7EB); // Broken-white stick bar for active quests
  static const Color highlightYellow = Color(0xFFFACC15); // Level badge & Map target distance
  static const Color errorRed = Color(0xFFEF4444); // Error & HP penalty
  static const Color successGreen = Color(0xFF10B981);

  // 6 Stats Acquisition Colors (FINAL - using SPD for Speed)
  static const Color str = Color(0xFFEF4444); // Red
  static const Color end = Color(0xFF10B981); // Green
  static const Color spd = Color(0xFFA855F7); // Purple (Speed)
  static const Color intel = Color(0xFF00D4FF); // Cyan
  static const Color app = Color(0xFFFF2A85); // Pink
  static const Color wil = Color(0xFFFFFFFF); // White

  // Strata Tier Colors
  static const Color strataSSS = Color(0xFFEF4444);
  static const Color strataSS = Color(0xFFDC2626);
  static const Color strataS = Color(0xFFB91C1C);
  static const Color strataA = Color(0xFFF97316);
  static const Color strataB = Color(0xFF00D4FF);
  static const Color strataC = Color(0xFF10B981);
  static const Color strataD = Color(0xFF60A5FA);
  static const Color strataE = Color(0xFFE5E7EB);

  // Rank Title Colors
  static const Color rankApostle = Color(0xFFA855F7);
  static const Color rankPreacher = Color(0xFFDC2626);
  static const Color rankSaint = Color(0xFFEAB308);
  static const Color rankEnlighted = Color(0xFF60A5FA);
  static const Color rankRookie = Color(0xFF00D4FF);
  static const Color rankBeginner = Color(0xFF9CA3AF);
  static const Color rankNovice = Color(0xFF7A8499);

  // Streak Flame Colors
  static const Color streakFlameYellow = Color(0xFFFACC15); // 1-6 days
  static const Color streakFlameOrange = Color(0xFFF97316); // 7-13 days
  static const Color streakFlameRed = Color(0xFFEF4444); // 14-29 days
  static const Color streakFlamePurple = Color(0xFFA855F7); // >= 30 days

  // Color Helper Functions
  static Color colorForStat(String statCode) {
    switch (statCode.toUpperCase()) {
      case 'STR':
        return str;
      case 'END':
        return end;
      case 'SPD':
        return spd;
      case 'INT':
        return intel;
      case 'APP':
        return app;
      case 'WIL':
        return wil;
      default:
        return textPrimary;
    }
  }

  static Color colorForStrata(String strata) {
    switch (strata.toUpperCase()) {
      case 'SSS':
        return strataSSS;
      case 'SS':
        return strataSS;
      case 'S':
        return strataS;
      case 'A':
        return strataA;
      case 'B':
        return strataB;
      case 'C':
        return strataC;
      case 'D':
        return strataD;
      case 'E':
      default:
        return strataE;
    }
  }

  static Color colorForRank(String rankTitle) {
    switch (rankTitle.toLowerCase()) {
      case 'apostle':
        return rankApostle;
      case 'preacher':
        return rankPreacher;
      case 'saint':
        return rankSaint;
      case 'enlighted':
        return rankEnlighted;
      case 'rookie':
        return rankRookie;
      case 'beginner':
        return rankBeginner;
      case 'novice':
      default:
        return rankNovice;
    }
  }

  static Color colorForStreak(int streakDays) {
    if (streakDays >= 30) return streakFlamePurple;
    if (streakDays >= 14) return streakFlameRed;
    if (streakDays >= 7) return streakFlameOrange;
    return streakFlameYellow;
  }
}
