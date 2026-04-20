import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../bookings/domain/entities/booking.dart';
import '../domain/entities/flight.dart';

/// Pushes next-flight data to the iOS WidgetKit extension via App Groups.
/// Call [update] whenever bookings change or the app foregrounds.
class WidgetUpdateService {
  static const _appGroup = 'group.com.jsx.jsxappcopy';
  static const _iOSWidgetName = 'JSXWidget';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroup);
  }

  static Future<void> update(List<Booking> bookings) async {
    final next = bookings
        .where((b) => b.isUpcoming)
        .toList()
      ..sort((a, b) => a.flight.departureTime.compareTo(b.flight.departureTime));

    final booking = next.isNotEmpty ? next.first : null;

    if (booking == null) {
      await _saveAll({
        'jsx_has_flight': false,
        'jsx_origin': '—',
        'jsx_destination': '—',
        'jsx_route': '—',
        'jsx_departure_time': 'No upcoming flights',
        'jsx_status': '',
        'jsx_confirmation': '',
        'jsx_minutes_away': 0,
        'jsx_time_away': '',
      });
    } else {
      final flight = booking.flight;
      final diff = flight.departureTime.difference(DateTime.now());
      final timeFmt = DateFormat('h:mm a');

      await _saveAll({
        'jsx_has_flight': true,
        'jsx_origin': flight.origin.code,
        'jsx_destination': flight.destination.code,
        'jsx_route': '${flight.origin.code}→${flight.destination.code}',
        'jsx_departure_time': timeFmt.format(flight.departureTime),
        'jsx_status': flight.status.label,
        'jsx_confirmation': booking.confirmationCode,
        'jsx_minutes_away': diff.inMinutes.clamp(0, 99999),
        'jsx_time_away': _formatDiff(diff),
      });
    }

    await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
  }

  static Future<void> _saveAll(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData(entry.key, entry.value);
    }
  }

  static String _formatDiff(Duration diff) {
    if (diff.inMinutes < 60) return '${diff.inMinutes}m away';
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (diff.inDays == 0) return '${h}h ${m}m away';
    return '${diff.inDays}d ${h.remainder(24)}h away';
  }
}
