import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/airport.dart';
import '../../domain/entities/flight.dart';

class SupabaseFlightDataSource {
  final SupabaseClient _client;
  SupabaseFlightDataSource(this._client);

  Future<List<Airport>> getAirports() async {
    final rows = await _client.from('airports').select().order('code');
    return rows.map(_airportFromRow).toList();
  }

  Future<List<Flight>> searchFlights({
    Airport? from,
    Airport? to,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final base = DateTime(d.year, d.month, d.day);

    var query = _client.from('flight_schedules').select(
      '*, origin:airports!flight_schedules_origin_code_fkey(*), '
      'dest:airports!flight_schedules_dest_code_fkey(*)',
    );

    if (from != null) query = query.eq('origin_code', from.code);
    if (to != null) query = query.eq('dest_code', to.code);

    final rows = await query;
    return rows.map((r) => _flightFromRow(r, base)).toList();
  }

  Airport _airportFromRow(Map<String, dynamic> r) =>
      Airport(code: r['code'], city: r['city'], name: r['name']);

  Flight _flightFromRow(Map<String, dynamic> r, DateTime base) {
    final dep = base.add(Duration(
      hours: r['dep_hour'] as int,
      minutes: r['dep_minute'] as int,
    ));
    final arr = dep.add(Duration(minutes: r['dur_minutes'] as int));
    return Flight(
      id: r['id'],
      origin: _airportFromRow(r['origin'] as Map<String, dynamic>),
      destination: _airportFromRow(r['dest'] as Map<String, dynamic>),
      departureTime: dep,
      arrivalTime: arr,
      aircraft: r['aircraft'],
      totalSeats: r['total_seats'],
      availableSeats: r['avail_seats'],
      price: (r['price'] as num).toDouble(),
      status: _status(r['status']),
    );
  }

  FlightStatus _status(String s) => switch (s) {
        'boarding' => FlightStatus.boarding,
        'delayed' => FlightStatus.delayed,
        'landed' => FlightStatus.landed,
        'cancelled' => FlightStatus.cancelled,
        _ => FlightStatus.onTime,
      };
}
