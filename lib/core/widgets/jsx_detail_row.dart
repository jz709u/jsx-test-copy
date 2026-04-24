import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'jsx_text.dart';

/// A horizontal label/value row with consistent bottom spacing.
///
/// Defaults to bodyMedium label + titleSmall value — the standard detail-card
/// pattern used in flight, booking, and payment sections.
///
/// ```dart
/// JsxDetailRow('Flight', flight.id)
/// JsxDetailRow('Duration', flight.durationString)
///
/// // Flight-tracking info style: muted label, end-aligned flexible value
/// JsxDetailRow('Origin', airport.name,
///     labelVariant: JsxTextVariant.titleSmall,
///     labelColor: AppColors.textSecondary,
///     valueFlexible: true)
/// ```
class JsxDetailRow extends StatelessWidget {
  const JsxDetailRow(
    this.label,
    this.value, {
    super.key,
    this.labelVariant = JsxTextVariant.bodyMedium,
    this.valueVariant = JsxTextVariant.titleSmall,
    this.labelColor,
    this.valueColor,
    this.valueFlexible = false,
  });

  final String label;
  final String value;
  final JsxTextVariant labelVariant;
  final JsxTextVariant valueVariant;
  final Color? labelColor;
  final Color? valueColor;

  /// When true wraps the value in [Flexible] with end-alignment — used when
  /// values can be long (e.g. airport names).
  final bool valueFlexible;

  @override
  Widget build(BuildContext context) {
    final valueText = JsxText(
      value,
      valueVariant,
      color: valueColor,
      textAlign: valueFlexible ? TextAlign.end : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          JsxText(label, labelVariant, color: labelColor),
          if (valueFlexible) Flexible(child: valueText) else valueText,
        ],
      ),
    );
  }
}
