import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../flights/domain/entities/airport.dart';
import '../../../flights/domain/entities/flight.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/passenger.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../../../core/supabase/supabase_config.dart';

class SupabaseBookingRepository implements BookingRepository {
  final SupabaseClient _client;
  SupabaseBookingRepository(this._client);

  @override
  Future<List<Booking>> getBookings() async {
    final rows = await _client
        .from('bookings')
        .select(
          '*, '
          'flight:flights('
          '  *, '
          '  origin:airports!flights_origin_code_fkey(*), '
          '  dest:airports!flights_dest_code_fkey(*)'
          '), '
          'passengers(*)',
        )
        .eq('user_id', SupabaseConfig.devUserId)
        .order('departure_time');

    return rows.map(_bookingFromRow).toList();
  }

  @override
  Future<String> createBooking(Flight flight, int passengerCount) async {
    final code = _generateCode();
    final booking = await _client.from('bookings').insert({
      'user_id': SupabaseConfig.devUserId,
      'confirmation_code': code,
      'flight_id': flight.id,
      'departure_time': flight.departureTime.toUtc().toIso8601String(),
      'arrival_time': flight.arrivalTime.toUtc().toIso8601String(),
      'total_paid': flight.price * passengerCount,
      'status': 'confirmed',
    }).select().single();

    final pList = List.generate(passengerCount, (i) => {
      'booking_id': booking['id'],
      'first_name': i == 0 ? 'Alex' : 'Guest ${i + 1}',
      'last_name': 'Rivera',
    });
    await _client.from('passengers').insert(pList);

    await _client.rpc('decrement_seats', params: {
      'flight_id': flight.id,
      'count': passengerCount,
    });

    return code;
  }

  Booking _bookingFromRow(Map<String, dynamic> r) {
    final f = r['flight'] as Map<String, dynamic>;
    final origin = _airport(f['origin'] as Map<String, dynamic>);
    final dest = _airport(f['dest'] as Map<String, dynamic>);

    final flight = Flight(
      id: f['id'],
      origin: origin,
      destination: dest,
      departureTime: DateTime.parse(r['departure_time']).toLocal(),
      arrivalTime: DateTime.parse(r['arrival_time']).toLocal(),
      aircraft: f['aircraft'],
      totalSeats: f['total_seats'],
      availableSeats: f['avail_seats'],
      price: (f['price'] as num).toDouble(),
      status: _status(f['status']),
    );

    final passengers = (r['passengers'] as List)
        .map((p) => Passenger(firstName: p['first_name'], lastName: p['last_name']))
        .toList();

    return Booking(
      confirmationCode: r['confirmation_code'],
      flight: flight,
      passengers: passengers,
      totalPaid: (r['total_paid'] as num).toDouble(),
      bookedAt: DateTime.parse(r['booked_at']),
      status: _bookingStatus(r['status']),
      seatNumber: r['seat_number'] as int?,
    );
  }

  Airport _airport(Map<String, dynamic> r) =>
      Airport(code: r['code'], city: r['city'], name: r['name']);

  FlightStatus _status(String s) => switch (s) {
        'boarding' => FlightStatus.boarding,
        'delayed' => FlightStatus.delayed,
        'landed' => FlightStatus.landed,
        'cancelled' => FlightStatus.cancelled,
        _ => FlightStatus.onTime,
      };

  BookingStatus _bookingStatus(String s) => switch (s) {
        'checked_in' => BookingStatus.checkedIn,
        'cancelled' => BookingStatus.cancelled,
        'completed' => BookingStatus.completed,
        _ => BookingStatus.confirmed,
      };

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return 'JSX${List.generate(4, (_) => chars[r.nextInt(chars.length)]).join()}';
  }
}
