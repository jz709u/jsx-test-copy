import 'flight.dart';

class FlightTrack {
  final String flightId;
  final double progress; // 0.0 → 1.0
  final double altitudeFt;
  final double speedMph;
  final double distanceRemainingMi;
  final int minutesRemaining;
  final FlightTrackPhase phase;

  const FlightTrack({
    required this.flightId,
    required this.progress,
    required this.altitudeFt,
    required this.speedMph,
    required this.distanceRemainingMi,
    required this.minutesRemaining,
    required this.phase,
  });

  static FlightTrack fromFlight(Flight flight) {
    final now = DateTime.now();
    final dep = flight.departureTime;
    final arr = flight.arrivalTime;
    final total = arr.difference(dep);

    if (now.isBefore(dep)) {
      return FlightTrack(
        flightId: flight.id,
        progress: 0,
        altitudeFt: 0,
        speedMph: 0,
        distanceRemainingMi: _routeDistance(flight),
        minutesRemaining: dep.difference(now).inMinutes,
        phase: FlightTrackPhase.preDeparture,
      );
    }

    if (now.isAfter(arr)) {
      return FlightTrack(
        flightId: flight.id,
        progress: 1,
        altitudeFt: 0,
        speedMph: 0,
        distanceRemainingMi: 0,
        minutesRemaining: 0,
        phase: FlightTrackPhase.landed,
      );
    }

    final elapsed = now.difference(dep);
    final progress = elapsed.inSeconds / total.inSeconds;
    final remaining = arr.difference(now);
    final distance = _routeDistance(flight);

    return FlightTrack(
      flightId: flight.id,
      progress: progress.clamp(0.0, 1.0),
      altitudeFt: _altitude(progress),
      speedMph: _speed(progress),
      distanceRemainingMi: distance * (1 - progress),
      minutesRemaining: remaining.inMinutes,
      phase: _phase(progress),
    );
  }

  static double _altitude(double p) {
    if (p < 0.1) return 37000 * (p / 0.1);
    if (p > 0.9) return 37000 * ((1 - p) / 0.1);
    return 37000;
  }

  static double _speed(double p) {
    if (p < 0.08) return 480 * (p / 0.08);
    if (p > 0.92) return 480 * ((1 - p) / 0.08);
    return 480 + (p * 40 - 20).abs(); // slight cruise variation
  }

  static FlightTrackPhase _phase(double p) {
    if (p < 0.1) return FlightTrackPhase.climbing;
    if (p > 0.9) return FlightTrackPhase.descending;
    return FlightTrackPhase.cruising;
  }

  static double _routeDistance(Flight flight) {
    // Mock distances by route pair
    const distances = {
      'DAL-BUR': 1235.0, 'BUR-DAL': 1235.0,
      'DAL-LAS': 1232.0, 'LAS-DAL': 1232.0,
      'DAL-OAK': 1461.0, 'OAK-DAL': 1461.0,
      'DAL-AUS': 195.0,  'AUS-DAL': 195.0,
      'BUR-LAS': 228.0,  'LAS-BUR': 228.0,
    };
    final key = '${flight.origin.code}-${flight.destination.code}';
    return distances[key] ?? 800.0;
  }
}

enum FlightTrackPhase { preDeparture, climbing, cruising, descending, landed }

extension FlightTrackPhaseLabel on FlightTrackPhase {
  String get label {
    switch (this) {
      case FlightTrackPhase.preDeparture: return 'Pre-Departure';
      case FlightTrackPhase.climbing: return 'Climbing';
      case FlightTrackPhase.cruising: return 'Cruising';
      case FlightTrackPhase.descending: return 'Descending';
      case FlightTrackPhase.landed: return 'Landed';
    }
  }
}
