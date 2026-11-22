import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/stat_calculator.dart';
import '../../controller/stats_controller.dart';
import '../../controller/user_controller.dart';
import '../../model/quest_log_model.dart';
import '../../model/user_model.dart';
import '../../routes/app_routes.dart';
import '../widgets/stat_radar_chart.dart';
import '../widgets/growth_line_chart.dart';

/// Screen 5 & 6: Stats Page with 2 Sub-Tabs:
/// - Sub-Tab 0: ATTRIBUTES (Radar chart, 2x3 matrix, and deletable quest logs)
/// - Sub-Tab 1: SEJARAH (Growth trajectory, 2x2 lifetime records, workout cumulative, and rank chronicle)
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure StatsController is available
    final statsController = Get.isRegistered<StatsController>()
        ? Get.find<StatsController>()
        : Get.put(StatsController());
    final userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final user = userController.user.value;
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return Column(
            children: [
              // 1. Header with Rank / PTS pill & Guide button '?'
              _buildTopHeader(user),

              // 2. Sub-Tab Switcher (ATTRIBUTES | SEJARAH)
              _buildSubTabSwitcher(statsController),

              // 3. Tab Body
              Expanded(
                child: statsController.selectedTab.value == 0
                    ? _buildAttributesTab(context, user, statsController)
                    : _buildSejarahTab(user, statsController),
              ),
            ],
          );
        }),
      ),
    );
  }

  // --- TOP HEADER ---

  Widget _buildTopHeader(UserModel user) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 21),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Text(
            'STATS',
            style: AppTextStyles.cinzel(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 2.5,
            ),
          ),

          // Right cluster: Rank·PTS Pill + Guide Button '?'
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.borderHairline, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${user.rank.toUpperCase()} · ',
                      style: AppTextStyles.dotGothic(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${user.totalStats} PTS',
                      style: AppTextStyles.dotGothic(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // System Guide '?' Button
              InkWell(
                onTap: () => Get.toNamed(AppRoutes.guide),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.primary, width: 1),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.help_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SUB-TAB SWITCHER ---

  Widget _buildSubTabSwitcher(StatsController controller) {
    final activeTab = controller.selectedTab.value;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ATTRIBUTES Tab
          Expanded(
            child: InkWell(
              onTap: () => controller.changeTab(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      'ATTRIBUTES',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: activeTab == 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        letterSpacing: 1.8,
                      ),
                    ),
                    if (activeTab == 0)
                      Positioned(
                        bottom: -12,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // SEJARAH Tab
          Expanded(
            child: InkWell(
              onTap: () => controller.changeTab(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      'SEJARAH',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: activeTab == 1
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        letterSpacing: 1.8,
                      ),
                    ),
                    if (activeTab == 1)
                      Positioned(
                        bottom: -12,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-TAB 0: ATTRIBUTES ---

  Widget _buildAttributesTab(
    BuildContext context,
    UserModel user,
    StatsController controller,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hexagonal Radar Chart
          StatRadarChart(user: user),

          const SizedBox(height: 20),

          // 2. 2x3 Matrix Attributes
          _buildAttributesMatrix(user),

          const SizedBox(height: 24),

          // 3. Quest Log Archive Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUEST LOG ARCHIVE',
                style: AppTextStyles.cinzel(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.6,
                ),
              ),
              Text(
                '${controller.questLogs.length} LOGGED',
                style: AppTextStyles.dotGothic(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Quest Log List
          _buildQuestLogsList(context, controller),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAttributesMatrix(UserModel user) {
    final stats = [
      _AttributeData('STR', 'STRENGTH', user.strength, AppColors.str),
      _AttributeData('END', 'ENDURANCE', user.endurance, AppColors.end),
      _AttributeData('SPD', 'SPEED', user.speed, AppColors.spd),
      _AttributeData('INT', 'INTELLECT', user.intelligence, AppColors.intel),
      _AttributeData('WIL', 'WILLPOWER', user.willpower, AppColors.wil),
      _AttributeData('APP', 'ALLURE', user.appearance, AppColors.app),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        final strata = StatCalculator.getStrata(stat.value);
        final strataColor = AppColors.colorForStrata(strata);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderHairline, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        color: stat.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stat.code,
                        style: AppTextStyles.cinzel(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: stat.color,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  // Dynamic Strata Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: strataColor, width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      strata,
                      style: AppTextStyles.dotGothic(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: strataColor,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${stat.value}',
                    style: AppTextStyles.dotGothic(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    stat.name,
                    style: AppTextStyles.labelMonoSmall(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestLogsList(BuildContext context, StatsController controller) {
    if (controller.questLogs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderHairline, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'NO QUEST LOGS RECORDED',
              style: AppTextStyles.cinzel(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete daily quests to archive telemetry',
              style: AppTextStyles.bodySmall(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.questLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = controller.questLogs[index];
        return _buildQuestLogCard(context, log, controller);
      },
    );
  }

  Widget _buildQuestLogCard(
    BuildContext context,
    QuestLogModel log,
    StatsController controller,
  ) {
    final iconData = _questIcon(log.questType);
    final formattedDate = DateFormat('dd MMM yyyy · HH:mm').format(log.completedAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quest Type Icon Box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.borderHairline, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              iconData,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Metas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.title,
                      style: AppTextStyles.cinzel(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '+${log.expGained} EXP',
                      style: AppTextStyles.dotGothic(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  log.metricSummary,
                  style: AppTextStyles.dotGothic(
                    fontSize: 12,
                    color: AppColors.textPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: AppTextStyles.labelMonoSmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Stat Rewards Chips
                    if (log.statRewards.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: log.statRewards.entries.map((e) {
                          return Text(
                            '+${e.value} ${e.key}',
                            style: AppTextStyles.dotGothic(
                              fontSize: 10,
                              color: AppColors.colorForStat(e.key),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete Log Button
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textSecondary,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'Purge Log',
            onPressed: () => _confirmDeleteLog(context, log.id, controller),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLog(
    BuildContext context,
    String logId,
    StatsController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderHairline, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          'PURGE QUEST RECORD',
          style: AppTextStyles.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          'This action permanently deletes this record from Hive storage.',
          style: AppTextStyles.bodySmall(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: AppTextStyles.button(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteQuestLog(logId);
            },
            child: Text(
              'PURGE',
              style: AppTextStyles.button(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-TAB 1: SEJARAH ---

  Widget _buildSejarahTab(UserModel user, StatsController controller) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Growth Trajectory Section
          _buildGrowthTrajectorySection(user, controller),

          const SizedBox(height: 20),

          // 2. 2x2 Lifetime Records Grid
          _buildLifetimeRecordsGrid(controller),

          const SizedBox(height: 24),

          // 3. Gothic Divider with centered diamond
          _buildGothicDiamondDivider(),

          const SizedBox(height: 24),

          // 4. Workout Cumulative Reps Section
          _buildWorkoutCumulativeSection(controller),

          const SizedBox(height: 24),

          // 5. Rank Chronicle Timeline Section
          _buildRankChronicleSection(controller),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGrowthTrajectorySection(
    UserModel user,
    StatsController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GROWTH TRAJECTORY',
              style: AppTextStyles.cinzel(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 1.6,
              ),
            ),
            Text(
              'DAY 01 - DAY ${controller.sortedGrowthSnapshots.length}',
              style: AppTextStyles.dotGothic(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Obsidian Chart Card Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderHairline, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${user.totalStats}',
                        style: AppTextStyles.dotGothic(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PTS CUMULATIVE',
                        style: AppTextStyles.labelMonoSmall(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.borderHairline, width: 1),
                    ),
                    child: Text(
                      'TOTAL STATS',
                      style: AppTextStyles.dotGothic(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Minimalist Line Chart
              GrowthLineChart(
                snapshots: controller.sortedGrowthSnapshots,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifetimeRecordsGrid(StatsController controller) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        // Cell 1: Longest Streak
        _buildRecordCard(
          title: 'LONGEST STREAK',
          value: '${controller.longestStreak} DAYS',
          valueColor: AppColors.secondary,
          badge: 'RECORD',
        ),
        // Cell 2: Total Cardio
        _buildRecordCard(
          title: 'TOTAL CARDIO',
          value: '${controller.totalCardioKm.toStringAsFixed(1)} KM',
          valueColor: AppColors.textPrimary,
          badge: 'DIST',
        ),
        // Cell 3: Total Study
        _buildRecordCard(
          title: 'TOTAL STUDY',
          value: '${controller.totalStudyHours.toStringAsFixed(1)} HRS',
          valueColor: AppColors.textPrimary,
          badge: 'INTEL',
        ),
        // Cell 4: Quests Cleared
        _buildRecordCard(
          title: 'QUESTS CLEARED',
          value: '${controller.totalQuestsCleared}',
          valueColor: AppColors.primary,
          badge: 'TOTAL',
        ),
      ],
    );
  }

  Widget _buildRecordCard({
    required String title,
    required String value,
    required Color valueColor,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.cinzel(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.dotGothic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              Text(
                badge,
                style: AppTextStyles.labelMonoSmall(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGothicDiamondDivider() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 1,
          color: AppColors.borderHairline,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: AppColors.background,
          child: Text(
            '◆',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.primary,
              shadows: [
                Shadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutCumulativeSection(StatsController controller) {
    final reps = controller.cumulativeWorkoutReps;
    final maxReps = controller.maxWorkoutReps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'WORKOUT CUMULATIVE',
              style: AppTextStyles.cinzel(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 1.6,
              ),
            ),
            Text(
              'TOTAL REPS',
              style: AppTextStyles.labelMonoSmall(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderHairline, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reps.length,
            separatorBuilder: (_, __) => const Divider(
              color: AppColors.borderHairline,
              height: 1,
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final key = reps.keys.elementAt(index);
              final count = reps[key] ?? 0;
              final ratio = maxReps > 0 ? (count / maxReps).clamp(0.0, 1.0) : 0.0;
              final isPullUps = key == 'Pull Ups';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          key.toUpperCase(),
                          style: AppTextStyles.cinzel(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '$count REPS',
                          style: AppTextStyles.dotGothic(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 2,
                      color: AppColors.background,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: ratio,
                        child: Container(
                          color: isPullUps ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankChronicleSection(StatsController controller) {
    final chronicle = controller.rankChronicle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RANK CHRONICLE',
              style: AppTextStyles.cinzel(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 1.6,
              ),
            ),
            Text(
              '${controller.currentUser?.rank.toUpperCase() ?? 'NOVICE'} ACTIVE',
              style: AppTextStyles.dotGothic(
                fontSize: 10,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderHairline, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Continuous Spine Line
              Positioned(
                left: 7,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 1,
                  color: AppColors.borderHairline,
                ),
              ),

              // Timeline Items
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chronicle.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final entry = chronicle[index];
                  final isCurrent = entry.isCurrent;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Node Diamond
                      Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.secondary
                                : AppColors.borderHairline,
                            width: 1,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '◆',
                            style: TextStyle(
                              fontSize: 7,
                              color: isCurrent
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Rank Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.rank.toUpperCase(),
                              style: AppTextStyles.cinzel(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.tierLabel,
                              style: AppTextStyles.dotGothic(
                                fontSize: 10,
                                color: isCurrent
                                    ? AppColors.secondary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Date Achieved
                      Text(
                        entry.dateAchieved,
                        style: AppTextStyles.dotGothic(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _questIcon(String type) {
    switch (type.toLowerCase()) {
      case 'workout':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'study':
        return Icons.menu_book;
      case 'grooming':
        return Icons.auto_awesome;
      default:
        return Icons.check_circle_outline;
    }
  }
}

class _AttributeData {
  final String code;
  final String name;
  final int value;
  final Color color;

  const _AttributeData(this.code, this.name, this.value, this.color);
}
