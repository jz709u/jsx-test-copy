import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'debug_actions.dart';
import 'debug_flights_viewer.dart';
import 'debug_flight_status_picker.dart';
import 'debug_widgets.dart';

class DebugDbSection extends StatefulWidget {
  final DebugActions? actions;
  const DebugDbSection({super.key, required this.actions});

  @override
  State<DebugDbSection> createState() => _DebugDbSectionState();
}

class _DebugDbSectionState extends State<DebugDbSection> {
  final Set<String> _loading = {};
  final Map<String, bool?> _result = {};

  bool get _disabled => widget.actions == null;

  Future<void> _run(String id, Future<void> Function() action) async {
    if (_loading.contains(id)) return;
    setState(() {
      _loading.add(id);
      _result.remove(id);
    });
    try {
      await action();
      if (mounted) setState(() => _result[id] = true);
    } catch (e) {
      if (mounted) {
        setState(() => _result[id] = false);
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading.remove(id));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: AppColors.white, fontSize: 13)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _openFlightsViewer(DebugActions actions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DebugFlightsViewer(actions: actions),
    );
  }

  void _openStatusPicker(DebugActions actions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DebugFlightStatusPicker(actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.actions;
    return Column(
      children: [
        DebugActionRow(
          id: 'seed',
          icon: Icons.restart_alt_rounded,
          label: 'Seed bookings',
          subtitle: 'Wipe + re-insert 4 dev-user bookings with fresh timestamps',
          loading: _loading, result: _result, disabled: _disabled,
          onTap: a == null ? null : () => _run('seed', a.seedBookings),
        ),
        DebugActionRow(
          id: 'seats',
          icon: Icons.airline_seat_recline_normal,
          label: 'Reset flight seats',
          subtitle: 'Restore avail_seats = total_seats for all flights',
          loading: _loading, result: _result, disabled: _disabled,
          onTap: a == null ? null : () => _run('seats', a.resetFlightSeats),
        ),
        DebugActionRow(
          id: 'stats',
          icon: Icons.person_outline,
          label: 'Reset user stats',
          subtitle: '12,450 pts · \$250.00 credit',
          loading: _loading, result: _result, disabled: _disabled,
          onTap: a == null ? null : () => _run('stats', a.resetUserStats),
        ),
        DebugActionRow(
          id: 'pts',
          icon: Icons.stars_rounded,
          label: 'Add +1,000 loyalty points',
          subtitle: 'Increments dev user\'s current total',
          loading: _loading, result: _result, disabled: _disabled,
          onTap: a == null ? null : () => _run('pts', () => a.addLoyaltyPoints(1000)),
        ),
        DebugActionRow(
          id: 'flights',
          icon: Icons.flight_rounded,
          label: 'View flights…',
          subtitle: 'Next 7 days of departures with seats & price',
          loading: _loading, result: _result, disabled: _disabled,
          onTap: a == null ? null : () => _openFlightsViewer(a),
        ),
        DebugActionRow(
          id: 'status',
          icon: Icons.edit_rounded,
          label: 'Set flight status…',
          subtitle: 'Pick a flight and change its status',
          loading: _loading, result: _result, disabled: _disabled,
          onTap: a == null ? null : () => _openStatusPicker(a),
        ),
        DebugActionRow(
          id: 'trigger_la',
          icon: Icons.play_circle_outline_rounded,
          label: 'Trigger live activity',
          subtitle: 'Invoke trigger-live-activity edge function now',
          loading: _loading, result: _result, disabled: _disabled,
          onTap: a == null ? null : () => _run('trigger_la', a.triggerLiveActivity),
        ),
        DebugActionRow(
          id: 'la',
          icon: Icons.clear_all_rounded,
          label: 'Clear live activities',
          subtitle: 'Deletes all rows from live_activities',
          loading: _loading, result: _result, disabled: _disabled,
          onTap: a == null ? null : () => _run('la', a.clearLiveActivities),
        ),
      ],
    );
  }
}
