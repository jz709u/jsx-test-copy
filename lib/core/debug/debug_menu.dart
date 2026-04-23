import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'backend_mode.dart';

void showDebugMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _DebugMenuSheet(),
  );
}

class _DebugMenuSheet extends ConsumerWidget {
  const _DebugMenuSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(backendModeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('DEBUG', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
                const SizedBox(width: 10),
                const Text('Backend', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Changes take effect immediately — data providers reload.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            ...BackendMode.values.map((mode) => _ModeRow(
                  mode: mode,
                  selected: mode == current,
                  onTap: () {
                    ref.read(backendModeProvider.notifier).state = mode;
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final BackendMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeRow({required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            Icon(
              _icon,
              size: 18,
              color: selected ? AppColors.gold : AppColors.textSecondary,
            ),
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
            if (selected) const Icon(Icons.check_rounded, size: 18, color: AppColors.gold),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    switch (mode) {
      case BackendMode.mock:  return Icons.memory_rounded;
      case BackendMode.local: return Icons.computer_rounded;
      case BackendMode.prod:  return Icons.cloud_rounded;
    }
  }
}
