import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum JsxTextVariant {
  displayLarge,
  displayMedium,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
  caption,
  mono,
}

/// Theme-aware text widget. Resolves style from [Theme.of(context).textTheme]
/// so changes to AppTheme propagate automatically.
///
/// ```dart
/// JsxText('Hello', JsxTextVariant.headlineMedium)
/// JsxText('JSX4K8P', JsxTextVariant.mono)
/// JsxText('Delayed', JsxTextVariant.labelSmall, color: AppColors.warning)
/// ```
class JsxText extends StatelessWidget {
  const JsxText(
    this.text,
    this.variant, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
  });

  final String text;
  final JsxTextVariant variant;

  /// Optional color override — only the color changes, everything else
  /// comes from the theme.
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    var style = _resolve(context);
    if (color != null || letterSpacing != null) {
      style = style.copyWith(color: color, letterSpacing: letterSpacing);
    }
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _resolve(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return switch (variant) {
      JsxTextVariant.displayLarge  => tt.displayLarge!,
      JsxTextVariant.displayMedium => tt.displayMedium!,
      JsxTextVariant.headlineLarge  => tt.headlineLarge!,
      JsxTextVariant.headlineMedium => tt.headlineMedium!,
      JsxTextVariant.headlineSmall  => tt.headlineSmall!,
      JsxTextVariant.titleLarge  => tt.titleLarge!,
      JsxTextVariant.titleMedium => tt.titleMedium!,
      JsxTextVariant.titleSmall  => tt.titleSmall!,
      JsxTextVariant.bodyLarge  => tt.bodyLarge!,
      JsxTextVariant.bodyMedium => tt.bodyMedium!,
      JsxTextVariant.bodySmall  => tt.bodySmall!,
      JsxTextVariant.labelLarge  => tt.labelLarge!,
      JsxTextVariant.labelMedium => tt.labelMedium!,
      JsxTextVariant.labelSmall  => tt.labelSmall!,
      // caption and mono aren't in TextTheme — fall back to AppTextStyles directly
      JsxTextVariant.caption => AppTextStyles.caption,
      JsxTextVariant.mono => AppTextStyles.mono,
    };
  }
}
