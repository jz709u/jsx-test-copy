import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A dark-gradient container with a subtle gold (or custom) border — the
/// standard premium card used throughout the app for flight paths, loyalty
/// cards, boarding passes, and club sections.
///
/// ```dart
/// JsxGradientCard(
///   child: ...,
/// )
///
/// // Custom amber tint for "next flight"
/// JsxGradientCard(
///   colors: const [Color(0xFF2A1F00), Color(0xFF1A1B25)],
///   borderAlpha: 0.3,
///   child: ...,
/// )
///
/// // Subtle white border for loyalty card
/// JsxGradientCard(
///   colors: const [Color(0xFF1A2040), Color(0xFF0D1220)],
///   borderColor: Colors.white,
///   borderAlpha: 0.08,
///   child: ...,
/// )
///
/// // With gold glow shadow (boarding pass)
/// JsxGradientCard(
///   glow: true,
///   margin: const EdgeInsets.all(AppSpacing.screenPadding),
///   child: ...,
/// )
/// ```
class JsxGradientCard extends StatelessWidget {
  const JsxGradientCard({
    super.key,
    required this.child,
    this.colors = const [Color(0xFF1A2040), Color(0xFF0D1530)],
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.borderColor = AppColors.gold,
    this.borderAlpha = 0.25,
    this.radius = AppRadius.sheet,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.margin,
    this.glow = false,
  });

  final Widget child;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Color borderColor;
  final double borderAlpha;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Adds a soft gold drop-shadow beneath the card (boarding pass style).
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: begin, end: end),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor.withValues(alpha: borderAlpha)),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: child,
      );
}
