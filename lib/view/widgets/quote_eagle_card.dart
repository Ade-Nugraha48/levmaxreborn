import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/quote_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Quote of the Day HUD Card featuring Cyberpunk Eagle Sigil
/// Conforms to `stitch_exports/05_home.html` and `docs/api_spec.md`.
class QuoteEagleCard extends StatelessWidget {
  const QuoteEagleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final quoteController = QuoteController.to;

    return GestureDetector(
      onTap: () => quoteController.fetchQuote(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141721),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: const Color(0xFF292A2F),
            width: 1,
          ),
        ),
        child: Obx(() {
          if (quoteController.isLoading.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            );
          }

          final quoteItem = quoteController.quote.value;
          final quoteText = quoteItem?.quote.isNotEmpty == true
              ? quoteItem!.quote
              : 'Discipline is choosing between what you want now and what you want most.';
          final authorText = quoteItem?.author.isNotEmpty == true
              ? quoteItem!.author.toUpperCase()
              : 'SYSTEM CODEX';

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stylized Eagle Sigil / Crest Icon
              Icon(
                Icons.military_tech_outlined,
                color: AppColors.primary.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(height: 6),
              // Quote Text
              Text(
                '"$quoteText"',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyDefault(
                  color: AppColors.textPrimary,
                ).copyWith(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              // Author Attribution
              Text(
                '— $authorText —',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMonoSmall(
                  color: AppColors.textSecondary,
                ).copyWith(
                  fontSize: 9,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
