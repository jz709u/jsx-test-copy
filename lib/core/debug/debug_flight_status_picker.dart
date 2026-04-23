import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'debug_actions.dart';
import 'debug_widgets.dart';

class DebugFlightStatusPicker extends StatefulWidget {
  final DebugActions actions;
  const DebugFlightStatusPicker({super.key, required this.actions});

  @override
  State<DebugFlightStatusPicker> createState() => _DebugFlightStatusPickerState();
}

class _DebugFlightStatusPickerState extends State<DebugFlightStatusPicker> {
  late Future<List<Map<String, dynamic>>> _flightsFuture;
  String? _updating;

  @override
  void initState() {
    super.initState();
    _flightsFuture = widget.actions.getFlights();
  }

  Future<void> _setStatus(String flightId, String status) async {
    setState(() => _updating = flightId);
    try {
      await widget.actions.setFlightStatus(flightId, status);
      if (mounted) setState(() => _flightsFuture = widget.actions.getFlights());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: const TextStyle(color: AppColors.white)),
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
          const DebugHandle(),
          const SizedBox(height: 16),
          const DebugSectionHeader(icon: Icons.edit_rounded, label: 'SET FLIGHT STATUS'),
          const SizedBox(height: 14),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _flightsFuture,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                );
              }
              if (snap.hasError) {
                return Text('${snap.error}', style: const TextStyle(color: AppColors.error));
              }
              return Column(
                children: snap.data!
                    .map((f) => _FlightStatusRow(
                          flight: f,
                          updating: _updating == f['id'],
                          onStatusTap: (s) => _setStatus(f['id'] as String, s),
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

  const _FlightStatusRow({
    required this.flight,
    required this.updating,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final id     = flight['id'] as String;
    final origin = flight['origin_code'] as String;
    final dest   = flight['dest_code'] as String;
    final status = flight['status'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(id,
                  style: const TextStyle(
                      color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('$origin → $dest',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              if (updating)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
              else
                DebugStatusChip(status),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: s == status
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: s == status
                                ? AppColors.gold.withValues(alpha: 0.6)
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: s == status ? AppColors.gold : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
