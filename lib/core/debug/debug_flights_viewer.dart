import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'debug_actions.dart';
import 'debug_flight_editor.dart';
import 'debug_widgets.dart';

class DebugFlightsViewer extends StatefulWidget {
  final DebugActions actions;
  const DebugFlightsViewer({super.key, required this.actions});

  @override
  State<DebugFlightsViewer> createState() => _DebugFlightsViewerState();
}

class _DebugFlightsViewerState extends State<DebugFlightsViewer> {
  late Future<List<Map<String, dynamic>>> _future;
  final Set<String> _booking = {};

  @override
  void initState() {
    super.initState();
    _future = widget.actions.getFlightsFull();
  }

  void _refresh() =>
      setState(() => _future = widget.actions.getFlightsFull());

  void _openEditor(Map<String, dynamic> flight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DebugFlightEditor(
        flight: flight,
        actions: widget.actions,
        onSaved: _refresh,
      ),
    );
  }

  Future<void> _book(Map<String, dynamic> flight) async {
    final id = flight['id'] as String;
    if (_booking.contains(id)) return;
    setState(() => _booking.add(id));
    try {
      final code = await widget.actions.bookFlight(flight);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Booked — $code',
            style: const TextStyle(color: AppColors.white, fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e',
            style: const TextStyle(color: AppColors.white, fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _booking.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const DebugHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              const DebugSectionHeader(
                  icon: Icons.flight_rounded, label: 'FLIGHTS'),
              const Spacer(),
              GestureDetector(
                onTap: _refresh,
                child: const Icon(Icons.refresh_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
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
                return Text('${snap.error}',
                    style: const TextStyle(color: AppColors.error));
              }
              final flights = List<Map<String, dynamic>>.from(snap.data ?? []);
              flights.sort((a, b) => (a['departure_at'] as String)
                  .compareTo(b['departure_at'] as String));
              return Column(
                children: flights
                    .map((f) => _FlightDetailRow(
                          flight: f,
                          booking: _booking.contains(f['id'] as String),
                          onTap: () => _openEditor(f),
                          onBook: () => _book(f),
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

class _FlightDetailRow extends StatelessWidget {
  final Map<String, dynamic> flight;
  final bool booking;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const _FlightDetailRow({
    required this.flight,
    required this.booking,
    required this.onTap,
    required this.onBook,
  });

  String _fmt(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    return '$mm/$dd $hh:$mn';
  }

  @override
  Widget build(BuildContext context) {
    final routeId = (flight['route_id'] as String?) ?? flight['id'] as String;
    final origin = flight['origin_code'] as String;
    final dest = flight['dest_code'] as String;
    final depIso = flight['departure_at'] as String;
    final arrIso = flight['arrival_at'] as String;
    final aircraft = flight['aircraft'] as String;
    final total = flight['total_seats'] as int;
    final avail = flight['avail_seats'] as int;
    final price = (flight['price'] as num).toDouble();
    final status = flight['status'] as String;

    final dep = _fmt(depIso);
    final arr = _fmt(arrIso);
    final durMin =
        DateTime.parse(arrIso).difference(DateTime.parse(depIso)).inMinutes;
    final dur = '${durMin ~/ 60}h ${durMin % 60}m';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Text(routeId,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                DebugStatusChip(status),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    size: 14, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$origin → $dest',
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$dep – $arr ($dur)',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                DebugChip(icon: Icons.airplanemode_active, label: aircraft),
                const SizedBox(width: 6),
                DebugChip(
                  icon: Icons.airline_seat_recline_normal,
                  label: '$avail / $total',
                  highlight: avail <= 5,
                ),
                const SizedBox(width: 6),
                DebugChip(
                    icon: Icons.attach_money,
                    label: '\$${price.toStringAsFixed(0)}'),
                const Spacer(),
                GestureDetector(
                  onTap: booking ? null : onBook,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: booking
                          ? AppColors.textMuted
                          : AppColors.gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: booking
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Book',
                            style: TextStyle(
                              color: AppColors.background,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
