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
        'jsx_departure_ts': '',
      });
    } else {
      final flight = booking.flight;
      final timeFmt = DateFormat('h:mm a');

      await _saveAll({
        'jsx_has_flight': true,
        'jsx_origin': flight.origin.code,
        'jsx_destination': flight.destination.code,
        'jsx_route': '${flight.origin.code}→${flight.destination.code}',
        'jsx_departure_time': timeFmt.format(flight.departureTime),
        'jsx_status': flight.status.label,
        'jsx_confirmation': booking.confirmationCode,
        'jsx_departure_ts': flight.departureTime.toUtc().toIso8601String(),
      });
    }

    await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
  }

  static Future<void> _saveAll(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData(entry.key, entry.value);
    }
  }
}
