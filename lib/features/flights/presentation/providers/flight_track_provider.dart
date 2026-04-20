import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_track.dart';

// Emits a fresh FlightTrack every 10 seconds to simulate live updates.
final flightTrackProvider =
    StreamProvider.family<FlightTrack, Flight>((ref, flight) async* {
  yield FlightTrack.fromFlight(flight);
  await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
    yield FlightTrack.fromFlight(flight);
  }
});
