import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/navigation_controller.dart';
import '../../controller/quest_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/player_status_card.dart';
import '../widgets/quote_eagle_card.dart';
import '../widgets/quest_card.dart';

/// Screen 3: Home Page (Mobile Tab 0)
/// Conforms to `stitch_exports/05_home.html` and `docs/design_blueprint.md`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = NavigationController.to;
    final questController = QuestController.to;

    // Check for HP warning or Penalty notification after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (questController.hasHpWarning.value) {
        questController.hasHpWarning.value = false;
        Get.defaultDialog(
          title: 'PROTOCOL DEVIATION',
          titleStyle: AppTextStyles.headingSmall(color: AppColors.errorRed),
          backgroundColor: AppColors.surface,
          radius: 4,
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'INACTIVITY DETECTED.\n-${questController.hpDeductionAmount} HP PENALTY DEDUCTED.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyDefault(color: AppColors.textPrimary),
            ),
          ),
          confirm: TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'ACKNOWLEDGE',
              style: AppTextStyles.buttonCinzel(color: AppColors.primary),
            ),
          ),
        );
      } else if (questController.hasPenaltyNotice.value) {
        questController.hasPenaltyNotice.value = false;
        Get.defaultDialog(
          title: 'CRITICAL PENALTY APPLIED',
          titleStyle: AppTextStyles.headingSmall(color: AppColors.errorRed),
          backgroundColor: AppColors.surface,
          radius: 4,
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '3-DAY INACTIVITY PENALTY TRIGGERED.\nALL STRATA REGRESSED 1 TIER.\nHP RESTORED TO 100.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyDefault(color: AppColors.textPrimary),
            ),
          ),
          confirm: TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'RE-ENGAGE SYSTEM',
              style: AppTextStyles.buttonCinzel(color: AppColors.primary),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 21),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF1E2538),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title HOME
                  Text(
                    'HOME',
                    style: AppTextStyles.headingMedium(
                      color: AppColors.textPrimary,
                    ).copyWith(letterSpacing: 2.5),
                  ),

                  // Top-Right Profile Avatar: Tap switches to Tab 3 (PROFILE)
                  GestureDetector(
                    onTap: () => nav.switchToProfile(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1F25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Player Status HUD Card
                    const PlayerStatusCard(),

                    const SizedBox(height: 13),

                    // 2. Eagle System Quote Strip
                    const QuoteEagleCard(),

                    const SizedBox(height: 21),

                    // 3. Daily Quests Module Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'DAILY QUESTS',
                              style: AppTextStyles.headingSmall(
                                color: AppColors.textPrimary,
                              ).copyWith(
                                fontSize: 13,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Obx(
                              () => Text(
                                questController.resetCountdown.value,
                                style: AppTextStyles.telemetryDotGothic(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Completed Ratio Badge: X / 5
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1F25),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: const Color(0xFF292A2F),
                                width: 1,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.telemetryDotGothic(
                                  fontSize: 11,
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${questController.completedCount} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '/ 5',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 4. Sorted Quests List (Active First, Done Dimmed at Bottom)
                    Obx(() {
                      final quests = questController.sortedQuests;
                      return Column(
                        children: quests.map((quest) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: QuestCard(
                              quest: quest,
                              onTap: () => questController.handleQuestTap(quest),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
