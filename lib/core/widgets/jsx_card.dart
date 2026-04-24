import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard surface card. Wrap any content that needs the app's default
/// elevated-surface treatment (background, radius, padding).
///
/// Use [color] to override the surface (e.g. gradient containers pass null
/// and handle decoration themselves via [decoration]).
class JsxCard extends StatelessWidget {
  const JsxCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.decoration,
    this.onTap,
    this.borderColor,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BoxDecoration? decoration;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppRadius.card;
    final effectiveDecoration = decoration ??
        BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(r),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1)
              : null,
        );

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: effectiveDecoration,
      child: child,
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }
}
