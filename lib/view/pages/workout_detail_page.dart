import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/quest_controller.dart';
import '../../controller/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/game_config.dart';
import '../../service/session_service.dart';
import '../widgets/grid_background.dart';

/// Screen 9: Workout Quest Execution Page
/// Conforms to `stitch_exports/10_workout_quest.html` and `docs/design_blueprint.md`.
class WorkoutDetailPage extends StatefulWidget {
  const WorkoutDetailPage({super.key});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late final String exerciseName;
  late final int workoutIndex;
  late final int totalSets;
  late final int targetReps;

  int currentSet = 1;
  int currentReps = 0;
  bool isResting = false;
  int restSecondsLeft = 30;
  Timer? _restTimer;
  bool isSubmitting = false;
  int _totalRepsAccumulated = 0;

  @override
  void initState() {
    super.initState();
    // Strictly ensure initial state starts at Set 1 and 0 reps
    currentSet = 1;
    currentReps = 0;
    isResting = false;
    restSecondsLeft = 30;
    isSubmitting = false;
    _totalRepsAccumulated = 0;

    final args = Get.arguments as Map<String, dynamic>?;
    exerciseName = args?['exercise'] as String? ?? 'Push Ups';
    workoutIndex = args?['exerciseIndex'] as int? ?? 0;

    final rank = UserController.to.currentUser?.rank ?? 'Novice';
    final rankTarget =
        GameConfig.rankTargets[rank] ?? GameConfig.rankTargets['Novice']!;
    totalSets = rankTarget.workoutSets;
    targetReps = rankTarget.repsPerExercise[exerciseName] ?? 10;
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      isResting = true;
      restSecondsLeft = 30;
      currentReps = 0;
    });

    if (Get.testMode || SessionService.skipRestTimer) {
      // In test mode or skipRestTimer demo mode, finish rest immediately
      setState(() {
        isResting = false;
        restSecondsLeft = 0;
        currentReps = 0;
      });
      return;
    }

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (restSecondsLeft > 1) {
        setState(() {
          restSecondsLeft--;
        });
      } else {
        timer.cancel();
        setState(() {
          isResting = false;
          restSecondsLeft = 0;
          currentReps = 0;
        });
      }
    });
  }

  void _skipRestTimer() {
    _restTimer?.cancel();
    setState(() {
      isResting = false;
      restSecondsLeft = 0;
      currentReps = 0;
    });
  }

  Future<void> _handleCompleteSet() async {
    // Guard clause: strictly require targetReps reached and not resting or submitting
    if (isSubmitting || isResting || currentReps < targetReps) {
      return;
    }

    _totalRepsAccumulated += currentReps;

    if (currentSet < totalSets) {
      setState(() {
        currentSet++;
        currentReps = 0; // Strictly reset reps to 0 for next set
      });
      _startRestTimer();
    } else {
      // Final set completed -> execute progression pipeline
      setState(() {
        isSubmitting = true;
      });

      final totalRepsCompleted = _totalRepsAccumulated;
      final result = await QuestController.to.completeQuest(
        type: QuestType.workout,
        exerciseName: exerciseName,
        workoutIndex: workoutIndex,
        repsCount: totalRepsCompleted,
      );

      if (!mounted) return;

      // Celebrate completion / Level Up
      if (result.levelUpResult.didLevelUp) {
        await Get.defaultDialog(
          title: 'LEVEL UP!',
          titleStyle: AppTextStyles.headingSmall(color: AppColors.highlightYellow),
          backgroundColor: AppColors.surface,
          radius: 4,
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Text(
                  'ACHIEVED LEVEL ${result.levelUpResult.newLevel}',
                  style: AppTextStyles.telemetryDotGothic(
                    fontSize: 16,
                    color: AppColors.highlightYellow,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+2 TO ALL 6 ATTRIBUTES\n(STR, END, SPD, INT, WIL, APP)',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyDefault(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          confirm: TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'CONTINUE',
              style: AppTextStyles.buttonCinzel(color: AppColors.primary),
            ),
          ),
        );
      } else {
        Get.snackbar(
          'QUEST COMPLETED',
          '+2 STR · +1 END · +25 EXP ACQUIRED',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          borderColor: AppColors.primary,
          borderWidth: 1,
          duration: const Duration(seconds: 2),
        );
      }

      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cadencePercent =
        ((currentSet - 1) / totalSets * 100).toInt().clamp(0, 100);
    final bool canComplete =
        !isSubmitting && !isResting && currentReps >= targetReps;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              // 1. Clean Detail Header (Back button + centered title only)
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Get.back(),
                    ),
                    Text(
                      'WORKOUT',
                      style: AppTextStyles.headingMedium(
                        color: AppColors.textPrimary,
                      ).copyWith(letterSpacing: 2.5),
                    ),
                    const SizedBox(width: 48), // Balanced spacing
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2. 38.2% Golden Ratio Upper Telemetry Deck
                      Center(
                        child: Column(
                          children: [
                            Text(
                              exerciseName.toUpperCase(),
                              style: AppTextStyles.headingLarge(
                                color: AppColors.textPrimary,
                              ).copyWith(fontSize: 26, letterSpacing: 2.2),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'RANK TARGET: $totalSets SETS × $targetReps REPS',
                              style: AppTextStyles.captionMeta(
                                color: AppColors.textSecondary,
                              ).copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Cyan Cadence Segmented Bar
                      Column(
                        children: [
                          Row(
                            children: List.generate(totalSets, (index) {
                              // Only previously completed sets are filled solid Cyan
                              final bool isCompleted = index < currentSet - 1;
                              final bool isCurrent = index == currentSet - 1;
                              final Color segColor = isCompleted
                                  ? AppColors.secondary
                                  : (isCurrent && isResting
                                      ? AppColors.primary
                                      : const Color(0xFF292A2F));

                              return Expanded(
                                child: Container(
                                  height: 3,
                                  margin: EdgeInsets.only(
                                    right: index < totalSets - 1 ? 6 : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: segColor,
                                    boxShadow: isCompleted
                                        ? [
                                            BoxShadow(
                                              color: AppColors.secondary
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CURRENT: SET 0$currentSet OF 0$totalSets',
                                style: AppTextStyles.telemetryDotGothic(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Text(
                                '$cadencePercent% CADENCE',
                                style: AppTextStyles.telemetryDotGothic(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF1E2538), height: 1),
                      const SizedBox(height: 16),

                      // 3. Rep Counter Tactical Module
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 21,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141721),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF25262C),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'REPETITIONS COMPLETED',
                              style: AppTextStyles.labelMonoSmall(
                                color: AppColors.textSecondary,
                              ).copyWith(letterSpacing: 2.0),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Decrement Button
                                InkWell(
                                  onTap: () {
                                    if (currentReps > 0) {
                                      setState(() => currentReps--);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D1018),
                                      border: Border.all(
                                        color: const Color(0xFF33343A),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.remove,
                                        color: AppColors.textPrimary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 24),

                                // Number Display (Starts at 0 / targetReps)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$currentReps',
                                      style: AppTextStyles.telemetryDotGothic(
                                        fontSize: 54,
                                        color: AppColors.textPrimary,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      ' / $targetReps',
                                      style: AppTextStyles.telemetryDotGothic(
                                        fontSize: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 24),

                                // Increment Button
                                InkWell(
                                  onTap: () {
                                    if (currentReps < 99) {
                                      setState(() => currentReps++);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D1018),
                                      border: Border.all(
                                        color: const Color(0xFF33343A),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add,
                                        color: AppColors.secondary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 13),

                      // Rest Telemetry Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1018),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: const Color(0xFF33343A),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isResting
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isResting
                                                ? AppColors.primary
                                                : AppColors.secondary)
                                            .withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'REST TIMER · ',
                                  style: AppTextStyles.labelMonoSmall(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  isResting ? '${restSecondsLeft}S' : 'READY',
                                  style: AppTextStyles.telemetryDotGothic(
                                    fontSize: 12,
                                    color: isResting
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (isResting)
                              GestureDetector(
                                onTap: _skipRestTimer,
                                child: Text(
                                  'SKIP',
                                  style: AppTextStyles.buttonCinzel(
                                    color: AppColors.secondary,
                                  ).copyWith(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 13),

                      // Auxiliary Stat Telemetry Tiles
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141721),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: const Color(0xFF25262C),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VOLUME LOAD',
                                    style: AppTextStyles.labelMonoSmall(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${totalSets * targetReps} REPS · BODYWEIGHT',
                                    style: AppTextStyles.telemetryDotGothic(
                                      fontSize: 11,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141721),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: const Color(0xFF25262C),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'STAT REWARDS',
                                    style: AppTextStyles.labelMonoSmall(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '+2 STR',
                                        style: AppTextStyles.telemetryDotGothic(
                                          fontSize: 11,
                                          color: AppColors.str,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '·',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+1 END',
                                        style: AppTextStyles.telemetryDotGothic(
                                          fontSize: 11,
                                          color: AppColors.end,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Primary CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: canComplete ? _handleCompleteSet : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            disabledBackgroundColor: const Color(0xFF1E2538),
                            disabledForegroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: canComplete ? 4 : 0,
                            shadowColor: canComplete
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentSet < totalSets
                                    ? 'COMPLETE SET $currentSet'
                                    : 'COMPLETE WORKOUT',
                                style: AppTextStyles.buttonCinzel(
                                  color: canComplete
                                      ? AppColors.background
                                      : AppColors.textSecondary,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.done_all,
                                color: canComplete
                                    ? AppColors.background
                                    : AppColors.textSecondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isResting
                            ? 'REST TIMER ACTIVE · STANDBY OR SKIP REST TO PROCEED'
                            : (currentReps < targetReps
                                ? 'REPETITIONS INCOMPLETE · REACH TARGET ($currentReps / $targetReps) TO UNLOCK'
                                : (currentSet < totalSets
                                    ? 'TAP TO COMPLETE SET $currentSet · REST TIMER ENGAGES NEXT'
                                    : 'FINAL SET COMPLETE · TAP TO FINISH WORKOUT & CLAIM REWARDS')),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMonoSmall(
                          color: canComplete
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                        ).copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
