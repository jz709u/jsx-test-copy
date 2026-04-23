import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'backend_mode.dart';

// ── Handle ────────────────────────────────────────────────────────────────────

class DebugHandle extends StatelessWidget {
  const DebugHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

// ── Section header ────────────────────────────────────────────────────────────

class DebugSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const DebugSectionHeader({super.key, required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'DEBUG',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      );
}

// ── Mode row (backend selector) ───────────────────────────────────────────────

class DebugModeRow extends StatelessWidget {
  final BackendMode mode;
  final bool selected;
  final VoidCallback onTap;
  const DebugModeRow({super.key, required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold.withValues(alpha: 0.08) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.gold.withValues(alpha: 0.5) : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(_icon, size: 17, color: selected ? AppColors.gold : AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mode.label,
                  style: TextStyle(
                    color: selected ? AppColors.gold : AppColors.white,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) const Icon(Icons.check_rounded, size: 17, color: AppColors.gold),
            ],
          ),
        ),
      );

  IconData get _icon => switch (mode) {
        BackendMode.mock  => Icons.memory_rounded,
        BackendMode.local => Icons.computer_rounded,
        BackendMode.prod  => Icons.cloud_rounded,
      };
}

// ── Action row ────────────────────────────────────────────────────────────────

class DebugActionRow extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final String subtitle;
  final Set<String> loading;
  final Map<String, bool?> result;
  final bool disabled;
  final VoidCallback? onTap;

  const DebugActionRow({
    super.key,
    required this.id,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.loading,
    required this.result,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = loading.contains(id);
    final res = result[id];
    final active = !disabled && !isLoading;

    return GestureDetector(
      onTap: active ? onTap : null,
      child: Opacity(
        opacity: disabled ? 0.38 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
              else if (res == true)
                const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success)
              else if (res == false)
                const Icon(Icons.error_rounded, size: 18, color: AppColors.error)
              else
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class DebugStatusChip extends StatelessWidget {
  final String status;
  const DebugStatusChip(this.status, {super.key});

  Color get _color => switch (status) {
        'on_time'   => AppColors.success,
        'delayed'   => AppColors.warning,
        'boarding'  => AppColors.gold,
        'cancelled' => AppColors.error,
        _           => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          status,
          style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
}

// ── Icon + label chip ─────────────────────────────────────────────────────────

class DebugChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  const DebugChip({super.key, required this.icon, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: highlight ? AppColors.warning : AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: highlight ? AppColors.warning : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      );
}
