import 'package:supabase_flutter/supabase_flutter.dart';

const _devUserId = 'a0000000-0000-0000-0000-000000000001';

const _seedCodes = ['JSX4K8P', 'JSX9M2R', 'JSXLT7Q', 'JSX8WXN'];

const flightStatuses = ['on_time', 'delayed', 'boarding', 'departed', 'landed', 'cancelled'];

class DebugActions {
  final SupabaseClient _db;
  DebugActions(this._db);

  // Wipe dev-user bookings and re-insert the 4 seeded ones with fresh timestamps.
  Future<void> seedBookings() async {
    await _db.from('bookings').delete().eq('user_id', _devUserId);

    final now = DateTime.now().toUtc();

    final rows = [
      {
        'user_id': _devUserId,
        'confirmation_code': 'JSX4K8P',
        'flight_id': 'JSX-1021',
        'departure_time': now.add(const Duration(days: 3, hours: 2)).toIso8601String(),
        'arrival_time':   now.add(const Duration(days: 3, hours: 4, minutes: 15)).toIso8601String(),
        'total_paid': 299,
        'status': 'confirmed',
        'seat_number': 7,
      },
      {
        'user_id': _devUserId,
        'confirmation_code': 'JSX9M2R',
        'flight_id': 'JSX-3050',
        'departure_time': now.add(const Duration(days: 14, hours: 3, minutes: 15)).toIso8601String(),
        'arrival_time':   now.add(const Duration(days: 14, hours: 5)).toIso8601String(),
        'total_paid': 199,
        'status': 'confirmed',
        'seat_number': null,
      },
      {
        'user_id': _devUserId,
        'confirmation_code': 'JSXLT7Q',
        'flight_id': 'JSX-2010',
        'departure_time': now.subtract(const Duration(days: 7, hours: 2)).toIso8601String(),
        'arrival_time':   now.subtract(const Duration(days: 6, hours: 23, minutes: 45)).toIso8601String(),
        'total_paid': 299,
        'booked_at': now.subtract(const Duration(days: 20)).toIso8601String(),
        'status': 'completed',
        'seat_number': 12,
      },
      {
        'user_id': _devUserId,
        'confirmation_code': 'JSX8WXN',
        'flight_id': 'JSX-4010',
        'departure_time': now.subtract(const Duration(days: 30, hours: 1)).toIso8601String(),
        'arrival_time':   now.subtract(const Duration(days: 29, hours: 22, minutes: 15)).toIso8601String(),
        'total_paid': 349,
        'booked_at': now.subtract(const Duration(days: 45)).toIso8601String(),
        'status': 'completed',
        'seat_number': 4,
      },
    ];

    await _db.from('bookings').insert(rows);

    // Re-insert passengers (cascade delete removed them with the bookings).
    final bookings = await _db
        .from('bookings')
        .select('id, confirmation_code')
        .inFilter('confirmation_code', _seedCodes);

    final passengers = <Map<String, dynamic>>[];
    for (final b in bookings) {
      final code = b['confirmation_code'] as String;
      if (code == 'JSX9M2R') {
        passengers.add({'booking_id': b['id'], 'first_name': 'Alex',   'last_name': 'Rivera'});
        passengers.add({'booking_id': b['id'], 'first_name': 'Jordan', 'last_name': 'Rivera'});
      } else {
        passengers.add({'booking_id': b['id'], 'first_name': 'Alex', 'last_name': 'Rivera'});
      }
    }
    if (passengers.isNotEmpty) await _db.from('passengers').insert(passengers);
  }

  // Restore available seats to total_seats for every flight.
  Future<void> resetFlightSeats() async {
    final flights = await _db.from('flight_schedules').select('id, total_seats');
    for (final f in flights) {
      await _db
          .from('flight_schedules')
          .update({'avail_seats': f['total_seats']})
          .eq('id', f['id'] as String);
    }
  }

  // Reset dev user's loyalty points and credit balance to seed values.
  Future<void> resetUserStats() async {
    await _db
        .from('users')
        .update({'loyalty_points': 12450, 'credit_balance': 250.00})
        .eq('id', _devUserId);
  }

  // Add loyalty points to dev user.
  Future<void> addLoyaltyPoints(int delta) async {
    final row = await _db
        .from('users')
        .select('loyalty_points')
        .eq('id', _devUserId)
        .single();
    final current = (row['loyalty_points'] as num).toInt();
    await _db
        .from('users')
        .update({'loyalty_points': current + delta})
        .eq('id', _devUserId);
  }

  // Set a flight's status.
  Future<void> setFlightStatus(String flightId, String status) async {
    await _db
        .from('flight_schedules')
        .update({'status': status})
        .eq('id', flightId);
  }

  // Fetch all flights with their current status.
  Future<List<Map<String, dynamic>>> getFlights() async {
    final rows = await _db
        .from('flight_schedules')
        .select('id, origin_code, dest_code, status')
        .order('id');
    return List<Map<String, dynamic>>.from(rows);
  }

  // Delete all rows from live_activities.
  Future<void> clearLiveActivities() async {
    await _db.from('live_activities').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  }
}
