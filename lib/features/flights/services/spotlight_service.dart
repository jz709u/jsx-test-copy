import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../bookings/domain/entities/booking.dart';

class SpotlightService {
  static const _channel = MethodChannel('jsx.app/spotlight');
  static final _fmt = DateFormat('h:mm a, MMM d');

  static Future<void> indexBookings(List<Booking> bookings) async {
    try {
      final data = bookings
          .map((b) => {
                'confirmationCode': b.confirmationCode,
                'origin': b.flight.origin.code,
                'destination': b.flight.destination.code,
                'departureTime': _fmt.format(b.flight.departureTime),
              })
          .toList();
      await _channel.invokeMethod('index', data);
    } on PlatformException catch (_) {}
  }

  static Future<void> deleteAll() async {
    try {
      await _channel.invokeMethod('deleteAll');
    } on PlatformException catch (_) {}
  }
}
