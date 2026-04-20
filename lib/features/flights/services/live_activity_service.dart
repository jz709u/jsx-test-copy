import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../domain/entities/flight.dart';
import '../domain/entities/flight_track.dart';

/// Drives iOS Live Activities via a native MethodChannel.
/// Requires iOS 16.2+; calls are no-ops on other platforms.
class LiveActivityService {
  static const _channel = MethodChannel('jsx.app/live_activity');
  static final _timeFmt = DateFormat('h:mm a');

  static Future<void> start({
    required Flight flight,
    required FlightTrack track,
    required String confirmationCode,
  }) async {
    try {
      await _channel.invokeMethod('start', _buildArgs(flight, track, confirmationCode));
    } on PlatformException catch (_) {
      // Live Activities unavailable or denied — silently ignore.
    }
  }

  static Future<void> update({
    required Flight flight,
    required FlightTrack track,
    required String confirmationCode,
  }) async {
    try {
      await _channel.invokeMethod('update', _buildArgs(flight, track, confirmationCode));
    } on PlatformException catch (_) {}
  }

  static Future<void> end() async {
    try {
      await _channel.invokeMethod('end');
    } on PlatformException catch (_) {}
  }

  static Map<String, dynamic> _buildArgs(
    Flight flight,
    FlightTrack track,
    String confirmationCode,
  ) =>
      {
        'flightId': flight.id,
        'origin': flight.origin.code,
        'originCity': flight.origin.city,
        'destination': flight.destination.code,
        'destinationCity': flight.destination.city,
        'departureTime': _timeFmt.format(flight.departureTime),
        'arrivalTime': _timeFmt.format(flight.arrivalTime),
        'confirmationCode': confirmationCode,
        'status': flight.status.label,
        'phase': track.phase.name,
        'progress': track.progress,
        'minutesRemaining': track.minutesRemaining,
        'altitudeFt': track.altitudeFt.round(),
        'speedMph': track.speedMph.round(),
      };
}
