import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/airport.dart';
import '../../domain/entities/flight.dart';
import '../../domain/repositories/flight_repository.dart';

class SupabaseFlightRepository implements FlightRepository {
  final SupabaseClient _client;
  SupabaseFlightRepository(this._client);

  @override
  Future<List<Airport>> getAirports() async {
    final rows = await _client.from('airports').select().order('code');
    return rows.map(_airportFromRow).toList();
  }

  @override
  Future<List<Flight>> searchFlights({Airport? from, Airport? to, DateTime? date}) async {
    final d = date ?? DateTime.now();
    final start = DateTime.utc(d.year, d.month, d.day);
    final end = start.add(const Duration(days: 1));

    var query = _client.from('flights').select(
      '*, '
      'origin:airports!flights_origin_code_fkey(*), '
      'dest:airports!flights_dest_code_fkey(*)',
    );

    if (from != null) query = query.eq('origin_code', from.code);
    if (to != null)   query = query.eq('dest_code', to.code);
    query = query
        .gte('departure_at', start.toIso8601String())
        .lt('departure_at', end.toIso8601String());

    final rows = await query;
    return rows.map(_flightFromRow).toList();
  }

  Airport _airportFromRow(Map<String, dynamic> r) =>
      Airport(code: r['code'], city: r['city'], name: r['name']);

  Flight _flightFromRow(Map<String, dynamic> r) => Flight(
        id: r['id'],
        origin: _airportFromRow(r['origin'] as Map<String, dynamic>),
        destination: _airportFromRow(r['dest'] as Map<String, dynamic>),
        departureTime: DateTime.parse(r['departure_at'] as String).toLocal(),
        arrivalTime: DateTime.parse(r['arrival_at'] as String).toLocal(),
        aircraft: r['aircraft'],
        totalSeats: r['total_seats'],
        availableSeats: r['avail_seats'],
        price: (r['price'] as num).toDouble(),
        status: _status(r['status']),
      );

  FlightStatus _status(String s) => switch (s) {
        'boarding'  => FlightStatus.boarding,
        'delayed'   => FlightStatus.delayed,
        'landed'    => FlightStatus.landed,
        'cancelled' => FlightStatus.cancelled,
        _           => FlightStatus.onTime,
      };
}
