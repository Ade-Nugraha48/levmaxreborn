import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Screen 12: System Codex (Guide Page)
/// Comprehensive reference for 6 Stats Acquisition, Rank Progression,
/// Strata Tiers, and Inactivity Penalties.
class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Gothic Header with diamond divider
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Stat Acquisition
                    _buildSectionHeader('STAT ACQUISITION', '6 CORE ATTRIBUTES'),
                    const SizedBox(height: 10),
                    _buildStatAcquisitionCard(),

                    const SizedBox(height: 24),

                    // Section 2: Rank Progression
                    _buildSectionHeader('RANK PROGRESSION', 'TIER ORDER'),
                    const SizedBox(height: 10),
                    _buildRankProgressionCard(),

                    const SizedBox(height: 24),

                    // Section 3: Strata Tiers
                    _buildSectionHeader('STRATA TIERS', 'SCALE 0 - 200+'),
                    const SizedBox(height: 10),
                    _buildStrataTiersGrid(),

                    const SizedBox(height: 24),

                    // Section 4: Inactivity Penalty Protocol
                    _buildPenaltyNoticeCard(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                tooltip: 'Return to Stats',
              ),
              Expanded(
                child: Text(
                  'SYSTEM CODEX',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance spacer
            ],
          ),
        ),
        // Hairline Gothic Divider with Neon Pink Diamond
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 1,
              color: AppColors.borderHairline,
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              transform: Matrix4.rotationZ(0.785398),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.cinzel(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 1.8,
          ),
        ),
        Text(
          subtitle,
          style: AppTextStyles.dotGothic(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatAcquisitionCard() {
    const rows = [
      _StatRow(
        name: 'STRENGTH',
        code: 'STR',
        color: AppColors.str,
        rewardText: '+2 / Workout · +2 / Level Up',
      ),
      _StatRow(
        name: 'ENDURANCE',
        code: 'END',
        color: AppColors.end,
        rewardText: '+1 Workout · +2 Cardio · +2 / Level Up',
      ),
      _StatRow(
        name: 'SPEED',
        code: 'SPD',
        color: AppColors.spd,
        rewardText: '+1 to +4 / Cardio Pace · +2 / Level Up',
      ),
      _StatRow(
        name: 'INTELLECT',
        code: 'INT',
        color: AppColors.intel,
        rewardText: '+3 to +4 / Study · +2 / Level Up',
      ),
      _StatRow(
        name: 'ALLURE',
        code: 'APP',
        color: AppColors.app,
        rewardText: '+3 / Grooming · +2 / Level Up',
      ),
      _StatRow(
        name: 'WILLPOWER',
        code: 'WIL',
        color: AppColors.wil,
        rewardText: '+1 Login · +2 Full Clear · +2 / Level Up',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(
          color: AppColors.borderHairline,
          height: 1,
          thickness: 1,
        ),
        itemBuilder: (context, index) {
          final row = rows[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      row.name,
                      style: AppTextStyles.cinzel(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: row.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${row.code})',
                      style: AppTextStyles.labelMonoSmall(
                        color: row.color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Text(
                  row.rewardText,
                  style: AppTextStyles.dotGothic(
                    fontSize: 11,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankProgressionCard() {
    const ranks = [
      _RankRow(
        name: 'APOSTLE',
        req: '900 PTS + 1 Stat SSS',
        color: AppColors.rankApostle,
      ),
      _RankRow(
        name: 'PREACHER',
        req: '600 PTS + 1 Stat SS',
        color: AppColors.rankPreacher,
      ),
      _RankRow(
        name: 'SAINT',
        req: '400 PTS + 1 Stat S',
        color: AppColors.rankSaint,
      ),
      _RankRow(
        name: 'ENLIGHTED',
        req: '300 PTS',
        color: AppColors.rankEnlighted,
      ),
      _RankRow(
        name: 'ROOKIE',
        req: '200 PTS',
        color: AppColors.rankRookie,
      ),
      _RankRow(
        name: 'BEGINNER',
        req: '100 PTS',
        color: AppColors.rankBeginner,
      ),
      _RankRow(
        name: 'NOVICE',
        req: 'Default (0 PTS)',
        color: AppColors.rankNovice,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ranks.length,
        separatorBuilder: (_, __) => const Divider(
          color: AppColors.borderHairline,
          height: 1,
          thickness: 1,
        ),
        itemBuilder: (context, index) {
          final r = ranks[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  r.name,
                  style: AppTextStyles.cinzel(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: r.color,
                    letterSpacing: 1.4,
                  ),
                ),
                Text(
                  r.req,
                  style: AppTextStyles.dotGothic(
                    fontSize: 11,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStrataTiersGrid() {
    const strataList = [
      _StrataItem('SSS', '200+', AppColors.strataSSS),
      _StrataItem('B', '70 - 79', AppColors.strataB),
      _StrataItem('SS', '150 - 199', AppColors.strataSS),
      _StrataItem('C', '50 - 69', AppColors.strataC),
      _StrataItem('S', '100 - 149', AppColors.strataS),
      _StrataItem('D', '30 - 49', AppColors.strataD),
      _StrataItem('A', '80 - 99', AppColors.strataA),
      _StrataItem('E', '0 - 29', AppColors.strataE),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: strataList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final s = strataList[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderHairline, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.strata,
                style: AppTextStyles.cinzel(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: s.color,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                s.range,
                style: AppTextStyles.dotGothic(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPenaltyNoticeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
          top: BorderSide(color: AppColors.borderHairline, width: 1),
          right: BorderSide(color: AppColors.borderHairline, width: 1),
          bottom: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'INACTIVITY PENALTY PROTOCOL',
                style: AppTextStyles.cinzel(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '3 consecutive inactive days (0 HP) drops all 6 attributes by 1 strata tier to the lower upper bound. Rank is recalculated and HP resets to 100. Player Level and EXP are permanent and never drop.',
            style: AppTextStyles.bodySmall(
              color: AppColors.textSecondary,
            ).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _StatRow {
  final String name;
  final String code;
  final Color color;
  final String rewardText;

  const _StatRow({
    required this.name,
    required this.code,
    required this.color,
    required this.rewardText,
  });
}

class _RankRow {
  final String name;
  final String req;
  final Color color;

  const _RankRow({
    required this.name,
    required this.req,
    required this.color,
  });
}

class _StrataItem {
  final String strata;
  final String range;
  final Color color;

  const _StrataItem(this.strata, this.range, this.color);
}
