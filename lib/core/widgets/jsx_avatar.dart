import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'jsx_text.dart';

/// A circular avatar with a text label — used for passenger initials,
/// numbered seats, and user profile icons.
///
/// ```dart
/// // Passenger / seat number (default: 32px, gold tint bg)
/// JsxAvatar(label: '${i + 1}')
/// JsxAvatar(label: p.initials, variant: JsxTextVariant.labelSmall)
///
/// // Solid profile header (72px, gold bg, dark text, border)
/// JsxAvatar(
///   label: user.initials,
///   size: 72,
///   variant: JsxTextVariant.headlineLarge,
///   backgroundColor: AppColors.gold,
///   foregroundColor: AppColors.background,
///   border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 3),
/// )
///
/// // App-bar chip (38px, solid gold)
/// JsxAvatar(
///   label: user.initials,
///   size: 38,
///   variant: JsxTextVariant.titleMedium,
///   backgroundColor: AppColors.gold,
///   foregroundColor: AppColors.background,
/// )
/// ```
class JsxAvatar extends StatelessWidget {
  const JsxAvatar({
    super.key,
    required this.label,
    this.size = 32,
    this.variant = JsxTextVariant.titleSmall,
    this.backgroundColor,
    this.foregroundColor = AppColors.gold,
    this.border,
  });

  final String label;
  final double size;
  final JsxTextVariant variant;

  /// Defaults to [AppColors.gold] at 15 % opacity when null.
  final Color? backgroundColor;
  final Color foregroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.gold.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: border,
        ),
        child: Center(
          child: JsxText(label, variant, color: foregroundColor),
        ),
      );
}
