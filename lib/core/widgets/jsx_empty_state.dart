import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'jsx_button.dart';

/// Centered empty-state with icon, title, subtitle, and optional action button.
class JsxEmptyState extends StatelessWidget {
  const JsxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                JsxButton(
                  label: actionLabel!,
                  variant: JsxButtonVariant.secondary,
                  fullWidth: false,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      );
}
