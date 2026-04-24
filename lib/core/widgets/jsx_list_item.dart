import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'jsx_text.dart';

/// A grouped list container — renders [items] separated by dividers,
/// clipped to a rounded rectangle. Used for settings-style menus.
///
/// ```dart
/// JsxListGroup(items: [
///   JsxListItem(icon: Icons.person_outline, label: 'Personal Info', value: user.email, onTap: () {}),
///   JsxListItem(icon: Icons.lock_outline, label: 'Security', onTap: () {}),
/// ])
/// ```
class JsxListGroup extends StatelessWidget {
  const JsxListGroup({super.key, required this.items});

  final List<JsxListItem> items;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast) const Divider(height: 1, indent: 52),
              ],
            );
          }).toList(),
        ),
      );
}

/// A tappable row with an icon badge, label, optional value, and optional
/// trailing widget. Intended to live inside [JsxListGroup].
///
/// Supply [trailing] to render a custom widget (e.g. a status badge or
/// action button) at the end of the row. When [trailing] is null and
/// [showChevron] is true (the default) a standard chevron icon is shown.
class JsxListItem extends StatelessWidget {
  const JsxListItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.labelColor,
    this.trailing,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color? labelColor;
  final VoidCallback onTap;

  /// Custom trailing widget. Takes precedence over [showChevron] when set.
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: labelColor ?? AppColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JsxText(label, JsxTextVariant.titleMedium, color: labelColor),
                    if (value != null) ...[
                      const SizedBox(height: 1),
                      JsxText(value!, JsxTextVariant.bodySmall),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showChevron)
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}
