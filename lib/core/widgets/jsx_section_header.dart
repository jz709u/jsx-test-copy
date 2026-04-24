import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'jsx_text.dart';

/// Section heading with optional gold count pill.
class JsxSectionHeader extends StatelessWidget {
  const JsxSectionHeader({
    super.key,
    required this.title,
    this.count,
  });

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          JsxText(title, JsxTextVariant.headlineMedium),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: JsxText('$count', JsxTextVariant.labelMedium,
                  color: AppColors.gold),
            ),
          ],
        ],
      );
}
