import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'jsx_text.dart';

/// A centered value + label column used in loyalty cards and stat grids.
///
/// ```dart
/// JsxStatDisplay(value: '\$240', label: 'JSX Credit')
/// JsxStatDisplay(value: '1,200', label: 'Points', valueColor: AppColors.gold)
/// ```
class JsxStatDisplay extends StatelessWidget {
  const JsxStatDisplay({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
    this.valueVariant = JsxTextVariant.headlineLarge,
    this.labelVariant = JsxTextVariant.labelSmall,
  });

  final String value;
  final String label;

  /// Tints the value text — pass [AppColors.gold] to highlight.
  final Color? valueColor;
  final JsxTextVariant valueVariant;
  final JsxTextVariant labelVariant;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          JsxText(value, valueVariant, color: valueColor),
          const SizedBox(height: 2),
          JsxText(label, labelVariant, textAlign: TextAlign.center),
        ],
      );
}
