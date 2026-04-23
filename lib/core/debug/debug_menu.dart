import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'backend_mode.dart';
import 'debug_actions.dart';
import 'debug_db_section.dart';
import 'debug_widgets.dart';

void showDebugMenu(BuildContext context, {void Function()? onClose}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _DebugMenuSheet(),
  ).whenComplete(() => onClose?.call());
}

class _DebugMenuSheet extends ConsumerWidget {
  const _DebugMenuSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(backendModeProvider);
    final client  = ref.watch(supabaseClientProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const DebugHandle(),
          const SizedBox(height: 16),
          const DebugSectionHeader(icon: Icons.memory_rounded, label: 'BACKEND'),
          const SizedBox(height: 10),
          ...BackendMode.values.map((mode) => DebugModeRow(
                mode: mode,
                selected: mode == current,
                onTap: () => ref.read(backendModeProvider.notifier).state = mode,
              )),
          const SizedBox(height: 24),
          DebugSectionHeader(
            icon: Icons.storage_rounded,
            label: 'DATABASE',
            trailing: client == null
                ? const Text('switch to Supabase backend first',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11))
                : null,
          ),
          const SizedBox(height: 10),
          DebugDbSection(actions: client == null ? null : DebugActions(client)),
        ],
      ),
    );
  }
}
