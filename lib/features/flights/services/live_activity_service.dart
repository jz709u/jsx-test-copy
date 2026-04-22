import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/flight.dart';
import '../domain/entities/flight_track.dart';

/// Drives iOS Live Activities via a native MethodChannel and syncs the
/// APNs push token to Supabase so the backend can send remote updates.
class LiveActivityService {
  static const _channel = MethodChannel('jsx.app/live_activity');

  static Future<void> start({
    required Flight flight,
    required FlightTrack track,
    required String confirmationCode,
    String seat = '',
    String gate = '',
  }) async {
    try {
      print('[LA] starting live activity for ${flight.id}');
      await _channel.invokeMethod(
          'start', _buildArgs(flight, track, confirmationCode, seat: seat, gate: gate));
      print('[LA] start succeeded, polling for push token');
      _uploadPushToken(flight.id);
    } on PlatformException catch (e) {
      print('[LA] start failed: ${e.code} ${e.message}');
    }
  }

  static Future<void> update({
    required Flight flight,
    required FlightTrack track,
    required String confirmationCode,
    String seat = '',
    String gate = '',
  }) async {
    try {
      await _channel.invokeMethod(
          'update', _buildArgs(flight, track, confirmationCode, seat: seat, gate: gate));
    } on PlatformException catch (e) {
      print('[LA] update failed: ${e.code} ${e.message}');
    }
  }

  static Future<void> end(String flightId) async {
    try {
      await _channel.invokeMethod('end', {'flightId': flightId});
      print('[LA] ended live activity');
      await Supabase.instance.client
          .from('live_activities')
          .delete()
          .eq('flight_id', flightId);
    } on PlatformException catch (e) {
      print('[LA] end failed: ${e.code} ${e.message}');
    }
  }

  static Future<void> _uploadPushToken(String flightId) async {
    String? token;
    for (var i = 0; i < 60 && token == null; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        token = await _channel.invokeMethod<String>(
            'getActivityPushToken', {'flightId': flightId});
        print('[LA] poll $i: token=${token ?? "null"}');
      } on PlatformException catch (e) {
        print('[LA] poll $i getActivityPushToken error: ${e.code} ${e.message}');
      }
    }
    if (token == null) {
      print('[LA] push token never arrived after 30s, giving up');
      return;
    }
    print('[LA] uploading push token to Supabase: $token');
    try {
      await Supabase.instance.client.from('live_activities').upsert(
        {'flight_id': flightId, 'push_token': token},
        onConflict: 'flight_id',
      );
      print('[LA] push token uploaded successfully');
    } catch (e) {
      print('[LA] Supabase insert failed: $e');
    }
  }

  static String _phaseString(FlightTrackPhase phase) {
    switch (phase) {
      case FlightTrackPhase.preDeparture: return 'pre_departure';
      case FlightTrackPhase.climbing:     return 'en_route';
      case FlightTrackPhase.cruising:     return 'en_route';
      case FlightTrackPhase.descending:   return 'landing';
      case FlightTrackPhase.landed:       return 'landed';
    }
  }

  static Map<String, dynamic> _buildArgs(
    Flight flight,
    FlightTrack track,
    String confirmationCode, {
    String seat = '',
    String gate = '',
  }) =>
      {
        'flightId': flight.id,
        'origin': flight.origin.code,
        'originCity': flight.origin.city,
        'destination': flight.destination.code,
        'destinationCity': flight.destination.city,
        'departureTime': flight.departureTime.millisecondsSinceEpoch / 1000.0,
        'arrivalTime': flight.arrivalTime.millisecondsSinceEpoch / 1000.0,
        'confirmationCode': confirmationCode,
        'seat': seat,
        'gate': gate,
        'status': flight.status.label,
        'phase': _phaseString(track.phase),
        'progress': track.progress,
        'altitudeFt': track.altitudeFt.round(),
        'speedMph': track.speedMph.round(),
      };
}
