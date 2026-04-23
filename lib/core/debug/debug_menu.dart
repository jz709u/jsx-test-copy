import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'backend_mode.dart';
import 'debug_actions.dart';

void showDebugMenu(BuildContext context, {void Function()? onClose}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _DebugMenuSheet(),
  ).whenComplete(() {
    onClose?.call();
  });
}

// ── Root sheet ────────────────────────────────────────────────────────────────

class _DebugMenuSheet extends ConsumerWidget {
  const _DebugMenuSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(backendModeProvider);
    final client = ref.watch(supabaseClientProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _Handle(),
          const SizedBox(height: 16),
          _SectionHeader(icon: Icons.memory_rounded, label: 'BACKEND'),
          const SizedBox(height: 10),
          ...BackendMode.values.map((mode) => _ModeRow(
                mode: mode,
                selected: mode == current,
                onTap: () =>
                    ref.read(backendModeProvider.notifier).state = mode,
              )),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.storage_rounded,
            label: 'DATABASE',
            trailing: client == null
                ? const Text('switch to Supabase backend first',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11))
                : null,
          ),
          const SizedBox(height: 10),
          _DbSection(actions: client == null ? null : DebugActions(client)),
        ],
      ),
    );
  }
}

// ── Database actions section ──────────────────────────────────────────────────

class _DbSection extends StatefulWidget {
  final DebugActions? actions;
  const _DbSection({required this.actions});

  @override
  State<_DbSection> createState() => _DbSectionState();
}

class _DbSectionState extends State<_DbSection> {
  final Set<String> _loading = {};
  final Map<String, bool?> _result = {}; // true=ok, false=error

  bool get _disabled => widget.actions == null;

  Future<void> _run(String id, Future<void> Function() action) async {
    if (_loading.contains(id)) return;
    setState(() {
      _loading.add(id);
      _result.remove(id);
    });
    try {
      await action();
      if (mounted) {
        setState(() {
          _result[id] = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result[id] = false;
        });
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading.remove(id));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: AppColors.white, fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.actions;
    return Column(
      children: [
        _ActionRow(
          id: 'seed',
          icon: Icons.restart_alt_rounded,
          label: 'Seed bookings',
          subtitle:
              'Wipe + re-insert 4 dev-user bookings with fresh timestamps',
          loading: _loading,
          result: _result,
          disabled: _disabled,
          onTap: a == null ? null : () => _run('seed', a.seedBookings),
        ),
        _ActionRow(
          id: 'seats',
          icon: Icons.airline_seat_recline_normal,
          label: 'Reset flight seats',
          subtitle: 'Restore avail_seats = total_seats for all flights',
          loading: _loading,
          result: _result,
          disabled: _disabled,
          onTap: a == null ? null : () => _run('seats', a.resetFlightSeats),
        ),
        _ActionRow(
          id: 'stats',
          icon: Icons.person_outline,
          label: 'Reset user stats',
          subtitle: '12,450 pts · \$250.00 credit',
          loading: _loading,
          result: _result,
          disabled: _disabled,
          onTap: a == null ? null : () => _run('stats', a.resetUserStats),
        ),
        _ActionRow(
          id: 'pts',
          icon: Icons.stars_rounded,
          label: 'Add +1,000 loyalty points',
          subtitle: 'Increments dev user\'s current total',
          loading: _loading,
          result: _result,
          disabled: _disabled,
          onTap: a == null
              ? null
              : () => _run('pts', () => a.addLoyaltyPoints(1000)),
        ),
        _ActionRow(
          id: 'status',
          icon: Icons.edit_rounded,
          label: 'Set flight status…',
          subtitle: 'Pick a flight and change its status',
          loading: _loading,
          result: _result,
          disabled: _disabled,
          onTap: a == null ? null : () => _openFlightStatusPicker(context, a),
        ),
        _ActionRow(
          id: 'la',
          icon: Icons.clear_all_rounded,
          label: 'Clear live activities',
          subtitle: 'Deletes all rows from live_activities',
          loading: _loading,
          result: _result,
          disabled: _disabled,
          onTap: a == null ? null : () => _run('la', a.clearLiveActivities),
        ),
      ],
    );
  }

  void _openFlightStatusPicker(BuildContext context, DebugActions actions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FlightStatusPicker(actions: actions),
    );
  }
}

// ── Flight status picker ──────────────────────────────────────────────────────

class _FlightStatusPicker extends StatefulWidget {
  final DebugActions actions;
  const _FlightStatusPicker({required this.actions});

  @override
  State<_FlightStatusPicker> createState() => _FlightStatusPickerState();
}

class _FlightStatusPickerState extends State<_FlightStatusPicker> {
  late Future<List<Map<String, dynamic>>> _flightsFuture;
  String? _updating; // flight id currently being updated

  @override
  void initState() {
    super.initState();
    _flightsFuture = widget.actions.getFlights();
  }

  Future<void> _setStatus(String flightId, String status) async {
    setState(() => _updating = flightId);
    try {
      await widget.actions.setFlightStatus(flightId, status);
      setState(() {
        _flightsFuture = widget.actions.getFlights();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(),
              style: const TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _updating = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.88,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _Handle(),
          const SizedBox(height: 16),
          _SectionHeader(icon: Icons.edit_rounded, label: 'SET FLIGHT STATUS'),
          const SizedBox(height: 14),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _flightsFuture,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.gold),
                ));
              }
              if (snap.hasError) {
                return Text('${snap.error}',
                    style: const TextStyle(color: AppColors.error));
              }
              final flights = snap.data!;
              return Column(
                children: flights
                    .map((f) => _FlightStatusRow(
                          flight: f,
                          updating: _updating == f['id'],
                          onStatusTap: (status) =>
                              _setStatus(f['id'] as String, status),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FlightStatusRow extends StatelessWidget {
  final Map<String, dynamic> flight;
  final bool updating;
  final void Function(String status) onStatusTap;

  const _FlightStatusRow(
      {required this.flight,
      required this.updating,
      required this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    final id = flight['id'] as String;
    final origin = flight['origin_code'] as String;
    final dest = flight['dest_code'] as String;
    final status = flight['status'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(id,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('$origin → $dest',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              if (updating)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.gold))
              else
                _StatusChip(status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: flightStatuses
                .map((s) => GestureDetector(
                      onTap: updating ? null : () => onStatusTap(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: s == status
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: s == status
                                  ? AppColors.gold.withValues(alpha: 0.6)
                                  : AppColors.divider),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                color: s == status
                                    ? AppColors.gold
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const _SectionHeader(
      {required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6)),
            child: const Text('DEBUG',
                style: TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      );
}

class _ModeRow extends StatelessWidget {
  final BackendMode mode;
  final bool selected;
  final VoidCallback onTap;
  const _ModeRow(
      {required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.08)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(_icon,
                  size: 17,
                  color: selected ? AppColors.gold : AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(mode.label,
                      style: TextStyle(
                          color: selected ? AppColors.gold : AppColors.white,
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400))),
              if (selected)
                const Icon(Icons.check_rounded,
                    size: 17, color: AppColors.gold),
            ],
          ),
        ),
      );

  IconData get _icon {
    switch (mode) {
      case BackendMode.mock:
        return Icons.memory_rounded;
      case BackendMode.local:
        return Icons.computer_rounded;
      case BackendMode.prod:
        return Icons.cloud_rounded;
    }
  }
}

class _ActionRow extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final String subtitle;
  final Set<String> loading;
  final Map<String, bool?> result;
  final bool disabled;
  final VoidCallback? onTap;

  const _ActionRow({
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
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.gold))
              else if (res == true)
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: AppColors.success)
              else if (res == false)
                const Icon(Icons.error_rounded,
                    size: 18, color: AppColors.error)
              else
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  Color get _color {
    switch (status) {
      case 'on_time':
        return AppColors.success;
      case 'delayed':
        return AppColors.warning;
      case 'boarding':
        return AppColors.gold;
      case 'departed':
        return AppColors.textSecondary;
      case 'landed':
        return AppColors.textSecondary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6)),
        child: Text(status,
            style: TextStyle(
                color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}
