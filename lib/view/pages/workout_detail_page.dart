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
  bool isWorkoutCompleted = false;
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
    isWorkoutCompleted = false;
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

  void _incrementReps() {
    if (currentReps < targetReps) {
      setState(() => currentReps++);
    }
  }

  void _decrementReps() {
    if (currentReps > 0) {
      setState(() => currentReps--);
    }
  }

  Future<void> _handleCompleteSet() async {
    // Guard clause: strictly require targetReps reached and not resting, submitting, or already completed
    if (isSubmitting || isWorkoutCompleted || isResting || currentReps < targetReps) {
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

      setState(() {
        isWorkoutCompleted = true;
        isSubmitting = false;
      });

      // Show dedicated completion modal dialog
      await _showCompletionDialog(context, result, totalRepsCompleted);
    }
  }

  Future<void> _showCompletionDialog(
    BuildContext context,
    QuestCompletionResult result,
    int totalRepsCompleted,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.secondary, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        title: Center(
          child: Column(
            children: [
              Icon(
                result.levelUpResult.didLevelUp
                    ? Icons.military_tech
                    : Icons.check_circle_outline,
                size: 38,
                color: result.levelUpResult.didLevelUp
                    ? AppColors.highlightYellow
                    : AppColors.secondary,
              ),
              const SizedBox(height: 10),
              Text(
                result.levelUpResult.didLevelUp
                    ? 'LEVEL UP ASCENSION'
                    : 'WORKOUT PROTOCOL COMPLETE',
                textAlign: TextAlign.center,
                style: AppTextStyles.cinzel(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: result.levelUpResult.didLevelUp
                      ? AppColors.highlightYellow
                      : AppColors.textPrimary,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${exerciseName.toUpperCase()} · $totalSets SETS COMPLETED',
              textAlign: TextAlign.center,
              style: AppTextStyles.cinzel(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL VOLUME',
                        style: AppTextStyles.labelMonoSmall(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$totalRepsCompleted REPS',
                        style: AppTextStyles.telemetryDotGothic(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CADENCE STATUS',
                        style: AppTextStyles.labelMonoSmall(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '100% COMPLETE',
                        style: AppTextStyles.telemetryDotGothic(
                          fontSize: 13,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REWARDS ACQUIRED',
                        style: AppTextStyles.labelMonoSmall(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '+2 STR',
                            style: AppTextStyles.telemetryDotGothic(
                              fontSize: 12,
                              color: AppColors.str,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '·',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+1 END',
                            style: AppTextStyles.telemetryDotGothic(
                              fontSize: 12,
                              color: AppColors.end,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '·',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${result.expGained} EXP',
                            style: AppTextStyles.telemetryDotGothic(
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (result.levelUpResult.didLevelUp) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            AppColors.highlightYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.highlightYellow),
                      ),
                      child: Text(
                        'ASCENDED TO LV. ${result.levelUpResult.newLevel} (+2 ALL ATTRIBUTES)',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.telemetryDotGothic(
                          fontSize: 10,
                          color: AppColors.highlightYellow,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Get.back();
              },
              child: Text(
                'SELESAI',
                style: AppTextStyles.cinzel(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalTargetReps = totalSets * targetReps;
    final totalDoneReps = isWorkoutCompleted
        ? totalTargetReps
        : _totalRepsAccumulated + currentReps;
    final cadencePercent = totalTargetReps > 0
        ? ((totalDoneReps / totalTargetReps) * 100).toInt().clamp(0, 100)
        : 0;
    final bool canComplete = !isWorkoutCompleted &&
        !isSubmitting &&
        !isResting &&
        currentReps >= targetReps;
    final bool canDecrement =
        !isWorkoutCompleted && currentReps > 0 && !isResting && !isSubmitting;
    final bool canIncrement =
        !isWorkoutCompleted && currentReps < targetReps && !isResting && !isSubmitting;

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
                              // A set is completed if previously completed, or current set with full reps, or overall completed
                              final bool isCompleted = isWorkoutCompleted ||
                                  index < currentSet - 1 ||
                                  (index == currentSet - 1 &&
                                      currentReps >= targetReps);
                              final bool isCurrent =
                                  index == currentSet - 1 && !isCompleted;
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
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 6,
                                              spreadRadius: 0.5,
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
                                isWorkoutCompleted
                                    ? 'STATUS: ALL $totalSets SETS COMPLETED'
                                    : 'CURRENT: SET 0$currentSet OF 0$totalSets',
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
                                  onTap: canDecrement ? _decrementReps : null,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D1018),
                                      border: Border.all(
                                        color: canDecrement
                                            ? const Color(0xFF33343A)
                                            : const Color(0xFF1E2538),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.remove,
                                        color: canDecrement
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
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
                                  onTap: canIncrement ? _incrementReps : null,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D1018),
                                      border: Border.all(
                                        color: canIncrement
                                            ? const Color(0xFF33343A)
                                            : const Color(0xFF1E2538),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.add,
                                        color: canIncrement
                                            ? AppColors.secondary
                                            : AppColors.textMuted,
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
                            backgroundColor: isWorkoutCompleted
                                ? AppColors.surfaceElevated
                                : AppColors.primary,
                            foregroundColor: isWorkoutCompleted
                                ? AppColors.secondary
                                : AppColors.background,
                            disabledBackgroundColor: const Color(0xFF1E2538),
                            disabledForegroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: isWorkoutCompleted
                                  ? const BorderSide(color: AppColors.secondary, width: 1)
                                  : BorderSide.none,
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
                                isWorkoutCompleted
                                    ? 'WORKOUT COMPLETED'
                                    : (currentSet < totalSets
                                        ? 'COMPLETE SET $currentSet'
                                        : 'COMPLETE WORKOUT'),
                                style: AppTextStyles.buttonCinzel(
                                  color: isWorkoutCompleted
                                      ? AppColors.secondary
                                      : (canComplete
                                          ? AppColors.background
                                          : AppColors.textSecondary),
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.done_all,
                                color: isWorkoutCompleted
                                    ? AppColors.secondary
                                    : (canComplete
                                        ? AppColors.background
                                        : AppColors.textSecondary),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isWorkoutCompleted
                            ? 'WORKOUT PROTOCOL COMPLETED · SESSION CLEARED'
                            : (isResting
                                ? 'REST TIMER ACTIVE · STANDBY OR SKIP REST TO PROCEED'
                                : (currentReps < targetReps
                                    ? 'REPETITIONS INCOMPLETE · REACH TARGET ($currentReps / $targetReps) TO UNLOCK'
                                    : (currentSet < totalSets
                                        ? 'TAP TO COMPLETE SET $currentSet · REST TIMER ENGAGES NEXT'
                                        : 'FINAL SET COMPLETE · TAP TO FINISH WORKOUT & CLAIM REWARDS'))),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMonoSmall(
                          color: (canComplete || isWorkoutCompleted)
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
