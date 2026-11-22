import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/stat_calculator.dart';
import '../../controller/grooming_controller.dart';
import '../../model/grooming_item_model.dart';
import '../widgets/grid_background.dart';

/// Screen 11: Daily Grooming Detail Page
/// Provides Full Hive CRUD for daily grooming checklist rituals,
/// dynamic rank-based minimum quota validation, and quest submission.
/// Conforms to `docs/design_blueprint.md` (Screen 11), `docs/style.md`, and `stitch_exports/12_daily_grooming.html`.
class GroomingDetailPage extends StatelessWidget {
  const GroomingDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<GroomingController>()
        ? Get.find<GroomingController>()
        : Get.put(GroomingController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              // 1. Clean Detail Header (Back button left, centered title, action button right)
              _buildCleanHeader(context, controller),

              // 2. Scrollable Body Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
                  child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress & Reward Strip
                          _buildProgressTelemetryCard(controller),
                          const SizedBox(height: 21),

                          // Section Header: Ritual Objectives
                          _buildSectionHeader(controller),
                          const SizedBox(height: 8),

                          // Checklist Container (Full Hive CRUD)
                          _buildChecklistContainer(context, controller),
                          const SizedBox(height: 21),

                          // Secondary Telemetry: Bonus Stratum Card
                          _buildBonusStratumCard(),
                          const SizedBox(height: 28),

                          // Bottom Action Command Dock (Submit CTA)
                          _buildActionCommandDock(context, controller),
                          const SizedBox(height: 21),
                        ],
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. CLEAN DETAIL HEADER
  // ==========================================

  Widget _buildCleanHeader(BuildContext context, GroomingController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Go Back',
            onPressed: () => Get.back(),
          ),

          // Centered Title (Zero double slashes, zero decorative dots/boxes)
          Text(
            'DAILY GROOMING',
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: AppColors.textPrimary,
            ),
          ),

          // Action Button Right: Add Ritual Objective (+)
          IconButton(
            icon: const Icon(
              Icons.add,
              color: AppColors.primary,
              size: 22,
            ),
            tooltip: 'Add Ritual Objective',
            onPressed: () => _showAddDialog(context, controller),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. PROGRESS & REWARD TELEMETRY CARD
  // ==========================================

  Widget _buildProgressTelemetryCard(GroomingController controller) {
    final completed = controller.completedCount;
    final minReq = controller.minRequiredItems;
    final percent = controller.percentage;
    final isMet = controller.isThresholdMet;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Requirement Label & +3 APP Reward Box
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY PROTOCOL REQUIREMENT',
                style: GoogleFonts.dotGothic16(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '+3 APP',
                  style: GoogleFonts.dotGothic16(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metric Readout Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$completed / $minReq MINIMUM COMPLETED',
                style: GoogleFonts.dotGothic16(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '$percent%',
                style: GoogleFonts.dotGothic16(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Cyan Progress Bar Track
          LayoutBuilder(
            builder: (context, constraints) {
              final double trackWidth = constraints.maxWidth;
              final double fillWidth = (trackWidth * controller.progressRatio).clamp(0.0, trackWidth);

              return Container(
                width: double.infinity,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2538),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: fillWidth,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Status Note
          Text(
            isMet
                ? 'Quota threshold attained · APP stat unlock ready'
                : 'Quota deficient · ${minReq - completed} more required for protocol',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isMet ? AppColors.secondary : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. SECTION HEADER: RITUAL OBJECTIVES
  // ==========================================

  Widget _buildSectionHeader(GroomingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'RITUAL OBJECTIVES',
            style: GoogleFonts.cinzel(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
              color: AppColors.textSecondary,
            ),
          ),
          RichText(
            text: TextSpan(
              text: 'ACTIVE ',
              style: GoogleFonts.dotGothic16(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
              children: [
                TextSpan(
                  text: '${controller.totalCount}',
                  style: GoogleFonts.dotGothic16(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. CHECKLIST CONTAINER (HIVE FULL CRUD)
  // ==========================================

  Widget _buildChecklistContainer(BuildContext context, GroomingController controller) {
    if (controller.items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.checklist_rtl_outlined,
                color: AppColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'NO RITUAL OBJECTIVES CONFIGURED',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'TAP [+] IN HEADER TO INITIALIZE',
                style: GoogleFonts.dotGothic16(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.items.length,
        separatorBuilder: (_, __) => const Divider(
          color: AppColors.borderHairline,
          height: 1,
          thickness: 1,
        ),
        itemBuilder: (context, index) {
          final item = controller.items[index];
          return _buildChecklistRow(context, controller, item);
        },
      ),
    );
  }

  Widget _buildChecklistRow(
    BuildContext context,
    GroomingController controller,
    GroomingItemModel item,
  ) {
    final bool checked = item.isChecked;

    return InkWell(
      onTap: () => controller.toggleItem(item),
      borderRadius: BorderRadius.circular(4),
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: AppColors.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Cyberpunk Square Checkbox
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: checked ? AppColors.primary : AppColors.borderHairline,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF05060A),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Objective Title
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.cinzel(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: checked
                      ? AppColors.textPrimary
                      : AppColors.textPrimary.withValues(alpha: 0.85),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Action Icons: Edit & Delete
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Button
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Edit Objective',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showEditDialog(context, controller, item),
                ),
                const SizedBox(width: 4),

                // Delete Button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Delete Objective',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showDeleteDialog(context, controller, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. BONUS STRATUM CARD
  // ==========================================

  Widget _buildBonusStratumCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Pink Accent Pill
          Container(
            width: 3,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Bonus Stratum Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BONUS STRATUM',
                  style: GoogleFonts.dotGothic16(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Appearance Factor: ',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: 'Completing all daily objectives grants ',
                      ),
                      TextSpan(
                        text: '+50 EXP',
                        style: GoogleFonts.dotGothic16(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const TextSpan(
                        text: ' and shields APP strata tier from degradation.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. BOTTOM ACTION COMMAND DOCK (SUBMIT CTA)
  // ==========================================

  Widget _buildActionCommandDock(
    BuildContext context,
    GroomingController controller,
  ) {
    final bool alreadyDone = controller.isAlreadySubmitted;
    final bool isEligible = controller.isThresholdMet && !alreadyDone;
    final int minReq = controller.minRequiredItems;

    return Column(
      children: [
        // Primary Submit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isEligible && !controller.isLoading.value
                ? () => _handleSubmit(context, controller)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: alreadyDone
                  ? AppColors.surfaceElevated
                  : (isEligible ? AppColors.primary : AppColors.surfaceElevated),
              disabledBackgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: isEligible ? AppColors.primary : AppColors.borderHairline,
                  width: 1,
                ),
              ),
              elevation: isEligible ? 4 : 0,
              shadowColor: isEligible ? AppColors.primary.withValues(alpha: 0.4) : null,
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05060A)),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        alreadyDone
                            ? Icons.done_all
                            : (isEligible ? Icons.verified_outlined : Icons.lock_outline),
                        size: 18,
                        color: alreadyDone
                            ? AppColors.secondary
                            : (isEligible ? const Color(0xFF05060A) : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alreadyDone
                            ? 'PROTOCOL COMMITTED'
                            : (isEligible ? 'SUBMIT GROOMING' : 'THRESHOLD INCOMPLETE'),
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: alreadyDone
                              ? AppColors.secondary
                              : (isEligible ? const Color(0xFF05060A) : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),

        // Action Subtext
        Text(
          alreadyDone
              ? 'Protocol registered for today · Rewards claimed'
              : (isEligible
                  ? 'Minimum requirement met · Ready to commit protocol'
                  : 'Threshold incomplete · Complete at least $minReq rituals'),
          style: GoogleFonts.dotGothic16(
            fontSize: 10,
            letterSpacing: 1.2,
            color: alreadyDone
                ? AppColors.secondary
                : (isEligible ? AppColors.textSecondary : AppColors.primary.withValues(alpha: 0.85)),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ==========================================
  // 7. SUBMISSION HANDLER & LEVEL UP DIALOG
  // ==========================================

  Future<void> _handleSubmit(
    BuildContext context,
    GroomingController controller,
  ) async {
    final result = await controller.submitGrooming();
    if (result != null) {
      if (result.levelUpResult.didLevelUp) {
        if (context.mounted) {
          _showLevelUpDialog(context, result.levelUpResult);
        }
      } else {
        Get.snackbar(
          'GROOMING COMMITTED',
          '+3 APP · +25 EXP ACQUIRED',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceElevated,
          colorText: AppColors.primary,
          borderWidth: 1,
          borderColor: AppColors.primary.withValues(alpha: 0.4),
        );
      }
    }
  }

  void _showLevelUpDialog(BuildContext context, LevelUpResult levelUp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        title: Center(
          child: Text(
            'LEVEL UP PROTOCOL',
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 2.0,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ASCENSION ATTAINED',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'LV. ${levelUp.newLevel}',
              style: GoogleFonts.dotGothic16(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.highlightYellow,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Text(
                '+2 ALL ATTRIBUTES · LIMIT BREAK',
                style: GoogleFonts.dotGothic16(
                  fontSize: 12,
                  color: AppColors.secondary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.back();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'CLAIM ASCENSION',
                style: GoogleFonts.cinzel(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF05060A),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 8. CRUD DIALOGS: ADD, EDIT, DELETE
  // ==========================================

  void _showAddDialog(BuildContext context, GroomingController controller) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.borderHairline),
        ),
        title: Text(
          'NEW RITUAL OBJECTIVE',
          style: GoogleFonts.cinzel(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter ritual title for daily checklist protocol:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              style: GoogleFonts.cinzel(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceElevated,
                hintText: 'e.g. Skin Moisturizer, Cold Shower',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                await controller.addItem(text);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'ADD OBJECTIVE',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF05060A),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    GroomingController controller,
    GroomingItemModel item,
  ) {
    final textController = TextEditingController(text: item.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.borderHairline),
        ),
        title: Text(
          'EDIT RITUAL OBJECTIVE',
          style: GoogleFonts.cinzel(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update objective title:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              style: GoogleFonts.cinzel(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                await controller.editItem(item, text);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'SAVE CHANGES',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF05060A),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    GroomingController controller,
    GroomingItemModel item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.borderHairline),
        ),
        title: Text(
          'PURGE RITUAL OBJECTIVE',
          style: GoogleFonts.cinzel(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          'Remove "${item.title}" permanently from local Hive storage?',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.deleteItem(item);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'PURGE',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF05060A),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
