import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum JsxButtonVariant { primary, secondary, ghost, destructive }

/// Themed button with four variants.
///
/// - [primary]     Gold fill, dark label — main CTA.
/// - [secondary]   Outlined gold — secondary action.
/// - [ghost]       No border/fill, gold label — inline/tertiary action.
/// - [destructive] Error-colored outline — destructive actions.
class JsxButton extends StatelessWidget {
  const JsxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = JsxButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final JsxButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case JsxButtonVariant.primary:
        return _PrimaryButton(
          label: label, onPressed: onPressed,
          icon: icon, loading: loading, fullWidth: fullWidth,
        );
      case JsxButtonVariant.secondary:
        return _OutlinedButton(
          label: label, onPressed: onPressed,
          icon: icon, loading: loading, fullWidth: fullWidth,
          borderColor: AppColors.gold, labelColor: AppColors.gold,
        );
      case JsxButtonVariant.ghost:
        return _GhostButton(
          label: label, onPressed: onPressed,
          icon: icon, loading: loading, fullWidth: fullWidth,
        );
      case JsxButtonVariant.destructive:
        return _OutlinedButton(
          label: label, onPressed: onPressed,
          icon: icon, loading: loading, fullWidth: fullWidth,
          borderColor: AppColors.error, labelColor: AppColors.error,
        );
    }
  }
}

// ── Variants ──────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label, required this.onPressed,
    required this.icon, required this.loading, required this.fullWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: _ButtonContent(label: label, icon: icon, loading: loading,
            color: AppColors.background),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({
    required this.label, required this.onPressed,
    required this.icon, required this.loading, required this.fullWidth,
    required this.borderColor, required this.labelColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final Color borderColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: labelColor,
          side: BorderSide(color: borderColor.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: _ButtonContent(label: label, icon: icon, loading: loading,
            color: labelColor),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label, required this.onPressed,
    required this.icon, required this.loading, required this.fullWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 44,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: _ButtonContent(label: label, icon: icon, loading: loading,
            color: AppColors.gold),
      ),
    );
  }
}

// ── Shared content ────────────────────────────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label, required this.icon,
    required this.loading, required this.color,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2, color: color,
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}
