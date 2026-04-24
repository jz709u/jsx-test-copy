import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'jsx_text.dart';

/// Small inline label, optionally with a leading icon.
///
/// [JsxChip.icon] — icon + text row, used for metadata (aircraft, seats, price).
/// [JsxChip.nav]  — full-width tappable chip with trailing arrow (route grid, etc.)
class JsxChip extends StatelessWidget {
  const JsxChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.highlight = false,
  }) : _nav = false;

  /// Full-width chip with trailing chevron — for navigation/route lists.
  const JsxChip.nav({
    super.key,
    required this.label,
  })  : icon = null,
        color = null,
        highlight = false,
        _nav = true;

  final String label;
  final IconData? icon;
  final Color? color;

  /// When true, renders label and icon in [AppColors.warning].
  final bool highlight;

  final bool _nav;

  Color get _effectiveColor =>
      highlight ? AppColors.warning : (color ?? AppColors.textSecondary);

  @override
  Widget build(BuildContext context) {
    if (_nav) return _NavChip(label: label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: _effectiveColor),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            color: _effectiveColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  const _NavChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: AppSpacing.itemGap),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: JsxText(label, JsxTextVariant.titleSmall),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 10, color: AppColors.textMuted),
          ],
        ),
      );
}
