import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/quest_controller.dart';
import '../../controller/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/game_config.dart';
import '../widgets/grid_background.dart';

/// Screen 10: Study Lock-In Quest Page with Strict Penalty Protocol
/// Conforms to `stitch_exports/11_study_lock_in.html` and `docs/design_blueprint.md`.
class StudyDetailPage extends StatefulWidget {
  const StudyDetailPage({super.key});

  @override
  State<StudyDetailPage> createState() => _StudyDetailPageState();
}

class _StudyDetailPageState extends State<StudyDetailPage>
    with WidgetsBindingObserver {
  late final int targetMinutes;
  late final int totalSeconds;
  late int remainingSeconds;
  late final int intReward;

  bool isRunning = false;
  bool isPaused = false;
  bool isFinished = false;
  double integrity = 100.0;
  DateTime? backgroundPausedTime;
  Timer? _timer;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final user = UserController.to.currentUser;
    final rank = user?.rank ?? 'Novice';
    final rankTarget =
        GameConfig.rankTargets[rank] ?? GameConfig.rankTargets['Novice']!;
    targetMinutes = rankTarget.studyDurationMinutes;
    totalSeconds = targetMinutes * 60;
    remainingSeconds = totalSeconds;
    intReward = (rank == 'Apostle') ? 4 : 3;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (isRunning && !isPaused && !isFinished) {
        backgroundPausedTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (backgroundPausedTime != null && isRunning && !isPaused && !isFinished) {
        final elapsedSeconds =
            DateTime.now().difference(backgroundPausedTime!).inSeconds;
        backgroundPausedTime = null;

        if (elapsedSeconds > 10) {
          triggerProtocolViolation();
        }
      }
    }
  }

  /// Triggers strict protocol violation when app is abandoned for > 10 seconds
  void triggerProtocolViolation() {
    _timer?.cancel();
    setState(() {
      isPaused = true;
      integrity = (integrity - 10.0).clamp(0.0, 100.0);
    });

    Get.defaultDialog(
      title: 'STRICT PROTOCOL VIOLATION',
      titleStyle: AppTextStyles.headingSmall(color: AppColors.errorRed),
      backgroundColor: AppColors.surface,
      radius: 4,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              'TERMINAL ABANDONED FOR >10 SECONDS.\nLOCK-IN PROTOCOL HAS BEEN PAUSED.\nINTEGRITY COMPROMISED (-10.0%).',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyDefault(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
      confirm: TextButton(
        onPressed: () {
          Get.back();
        },
        child: Text(
          'ACKNOWLEDGE',
          style: AppTextStyles.buttonCinzel(color: AppColors.primary),
        ),
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      isRunning = true;
      isPaused = false;
    });

    if (Get.testMode) {
      // In test mode, finish immediately
      setState(() {
        remainingSeconds = 0;
        isFinished = true;
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 1) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          remainingSeconds = 0;
          isFinished = true;
          isRunning = false;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      isPaused = true;
    });
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _abortSession() {
    _timer?.cancel();
    Get.defaultDialog(
      title: 'TERMINATE SESSION',
      titleStyle: AppTextStyles.headingSmall(color: AppColors.errorRed),
      backgroundColor: AppColors.surface,
      radius: 4,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'ARE YOU SURE YOU WANT TO ABORT?\nALL PROGRESS IN THIS LOCK-IN SESSION WILL BE LOST.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyDefault(color: AppColors.textPrimary),
        ),
      ),
      confirm: TextButton(
        onPressed: () {
          Get.back(); // close dialog
          Get.back(); // return to home
        },
        child: Text(
          'CONFIRM ABORT',
          style: AppTextStyles.buttonCinzel(color: AppColors.errorRed),
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text(
          'CANCEL',
          style: AppTextStyles.buttonCinzel(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Future<void> _handleCompleteStudy() async {
    if (isSubmitting) return;
    setState(() {
      isSubmitting = true;
    });

    final result = await QuestController.to.completeQuest(
      type: QuestType.study,
      durationMinutes: targetMinutes,
    );

    if (!mounted) return;

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
        'STUDY LOCK-IN COMPLETED',
        '+$intReward INT · +25 EXP ACQUIRED',
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

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0
        ? (1.0 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0)
        : 1.0;
    final minutesStr = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secondsStr = (remainingSeconds % 60).toString().padLeft(2, '0');

    String statusLabel = 'LOCK-IN READY';
    Color statusColor = AppColors.secondary;
    if (isFinished) {
      statusLabel = 'LOCK-IN COMPLETE';
      statusColor = AppColors.primary;
    } else if (isPaused) {
      statusLabel = 'LOCK-IN PAUSED';
      statusColor = AppColors.errorRed;
    } else if (isRunning) {
      statusLabel = 'LOCK-IN ACTIVE';
      statusColor = AppColors.primary;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              // 1. Clean Detail Header
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
                      'STUDY TIMER',
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
                      const SizedBox(height: 12),

                      // 2. Circular Neon Pink Countdown Gauge (~61.8% allocation)
                      Center(
                        child: SizedBox(
                          width: 260,
                          height: 260,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background Track
                              const SizedBox(
                                width: 250,
                                height: 250,
                                child: CircularProgressIndicator(
                                  value: 1.0,
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1E1F25),
                                  ),
                                ),
                              ),
                              // Active Pink Luminescence Stroke
                              SizedBox(
                                width: 250,
                                height: 250,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3.5,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),

                              // Center Digital Readout & Status
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SESSION TARGET • $targetMinutes MIN',
                                    style: AppTextStyles.labelMonoSmall(
                                      color: AppColors.textSecondary,
                                    ).copyWith(letterSpacing: 1.8),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$minutesStr:$secondsStr',
                                    style: AppTextStyles.timerDisplay(
                                      color: AppColors.textPrimary,
                                    ).copyWith(fontSize: 44),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        statusLabel,
                                        style: AppTextStyles.labelMonoSmall(
                                          color: statusColor,
                                        ).copyWith(letterSpacing: 2.0),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. Telemetric Micro Metadata Strip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                'INT GAIN',
                                style: AppTextStyles.labelMonoSmall(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+$intReward INT',
                                style: AppTextStyles.telemetryDotGothic(
                                  fontSize: 13,
                                  color: AppColors.spd,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('◆',
                                style: TextStyle(
                                    fontSize: 8, color: Color(0xFF33343A))),
                          ),
                          Column(
                            children: [
                              Text(
                                'INTEGRITY',
                                style: AppTextStyles.labelMonoSmall(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${integrity.toStringAsFixed(1)}%',
                                style: AppTextStyles.telemetryDotGothic(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('◆',
                                style: TextStyle(
                                    fontSize: 8, color: Color(0xFF33343A))),
                          ),
                          Column(
                            children: [
                              Text(
                                'HARVEST',
                                style: AppTextStyles.labelMonoSmall(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+25 EXP',
                                style: AppTextStyles.telemetryDotGothic(
                                  fontSize: 13,
                                  color: AppColors.secondary,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // 4. Strict Disciplinary Penalty Note
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF141721),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: const Color(0xFF25262C),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 54,
                              color: AppColors.primary,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STRICT PENALTY PROTOCOL',
                                      style: AppTextStyles.labelMonoSmall(
                                        color: AppColors.primary,
                                      ).copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Leaving the app for more than 10 seconds will pause your session and compromise accrued intelligence yield.',
                                      style: AppTextStyles.captionMeta(
                                        color: AppColors.textSecondary,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 5. Bottom Action Dock
                      if (!isFinished) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!isRunning) {
                                _startTimer();
                              } else if (isPaused) {
                                _resumeTimer();
                              } else {
                                _pauseTimer();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 4,
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  !isRunning || isPaused
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  color: AppColors.background,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  !isRunning
                                      ? 'START LOCK-IN'
                                      : isPaused
                                          ? 'RESUME LOCK-IN'
                                          : 'PAUSE LOCK-IN',
                                  style: AppTextStyles.buttonCinzel(
                                    color: AppColors.background,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isRunning || isPaused) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _abortSession,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('◆',
                                    style: TextStyle(
                                        fontSize: 8,
                                        color: AppColors.errorRed)),
                                const SizedBox(width: 6),
                                Text(
                                  'ABORT ENGAGEMENT',
                                  style: AppTextStyles.labelMonoSmall(
                                    color: AppColors.textSecondary,
                                  ).copyWith(letterSpacing: 2.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        // Finished state -> Complete button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _handleCompleteStudy,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 4,
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check,
                                  color: AppColors.background,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'COMPLETE LOCK-IN',
                                  style: AppTextStyles.buttonCinzel(
                                    color: AppColors.background,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Demo Fast-Forward Helper
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              remainingSeconds = 0;
                              isFinished = true;
                              isRunning = false;
                            });
                          },
                          child: Text(
                            'DEMO: FAST-FORWARD TIMER',
                            style: AppTextStyles.labelMonoSmall(
                              color: AppColors.textSecondary.withValues(alpha: 0.6),
                            ).copyWith(fontSize: 9),
                          ),
                        ),
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
