import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

const _devUserId = 'a0000000-0000-0000-0000-000000000001';

const _seedCodes = ['JSX4K8P', 'JSX9M2R', 'JSXLT7Q', 'JSX8WXN'];

const flightStatuses = ['on_time', 'delayed', 'boarding', 'departed', 'landed', 'cancelled'];

class DebugActions {
  final SupabaseClient _db;
  DebugActions(this._db);

  // ── Seed bookings ──────────────────────────────────────────────────────────

  Future<void> seedBookings() async {
    await _db.from('bookings').delete().inFilter('confirmation_code', _seedCodes);

    final now = DateTime.now().toUtc();

    // Compute concrete departure times using each route's scheduled hour/minute.
    final dep1 = _routeDep(now, 3,   7, 30);   // JSX-1021  today+3
    final dep2 = _routeDep(now, 14,  9, 15);   // JSX-3050  today+14
    final dep3 = _routeDep(now, -7,  8,  0);   // JSX-2010  today-7
    final dep4 = _routeDep(now, -30, 6, 45);   // JSX-4010  today-30

    final f1Id = 'JSX-1021-${_dateStr(dep1)}';
    final f2Id = 'JSX-3050-${_dateStr(dep2)}';
    final f3Id = 'JSX-2010-${_dateStr(dep3)}';
    final f4Id = 'JSX-4010-${_dateStr(dep4)}';

    // Upsert the 4 flight rows so FK is satisfied even if the migration
    // generate_series window doesn't reach these dates.
    await _db.from('flights').upsert([
      {
        'id': f1Id, 'route_id': 'JSX-1021',
        'origin_code': 'DAL', 'dest_code': 'BUR',
        'departure_at': dep1.toIso8601String(),
        'arrival_at': dep1.add(const Duration(hours: 2, minutes: 15)).toIso8601String(),
        'aircraft': 'Embraer E135', 'total_seats': 30, 'avail_seats': 12,
        'price': 299, 'status': 'on_time',
      },
      {
        'id': f2Id, 'route_id': 'JSX-3050',
        'origin_code': 'DAL', 'dest_code': 'LAS',
        'departure_at': dep2.toIso8601String(),
        'arrival_at': dep2.add(const Duration(hours: 1, minutes: 45)).toIso8601String(),
        'aircraft': 'Embraer E135', 'total_seats': 30, 'avail_seats': 22,
        'price': 199, 'status': 'on_time',
      },
      {
        'id': f3Id, 'route_id': 'JSX-2010',
        'origin_code': 'BUR', 'dest_code': 'DAL',
        'departure_at': dep3.toIso8601String(),
        'arrival_at': dep3.add(const Duration(hours: 2, minutes: 15)).toIso8601String(),
        'aircraft': 'Embraer E135', 'total_seats': 30, 'avail_seats': 9,
        'price': 299, 'status': 'on_time',
      },
      {
        'id': f4Id, 'route_id': 'JSX-4010',
        'origin_code': 'DAL', 'dest_code': 'OAK',
        'departure_at': dep4.toIso8601String(),
        'arrival_at': dep4.add(const Duration(hours: 2, minutes: 45)).toIso8601String(),
        'aircraft': 'Embraer E135', 'total_seats': 30, 'avail_seats': 3,
        'price': 349, 'status': 'on_time',
      },
    ]);

    final rows = [
      {
        'user_id': _devUserId,
        'confirmation_code': 'JSX4K8P',
        'flight_id': f1Id,
        'departure_time': dep1.toIso8601String(),
        'arrival_time': dep1.add(const Duration(hours: 2, minutes: 15)).toIso8601String(),
        'total_paid': 299,
        'booked_at': now.toIso8601String(),
        'status': 'confirmed',
        'seat_number': 7,
      },
      {
        'user_id': _devUserId,
        'confirmation_code': 'JSX9M2R',
        'flight_id': f2Id,
        'departure_time': dep2.toIso8601String(),
        'arrival_time': dep2.add(const Duration(hours: 1, minutes: 45)).toIso8601String(),
        'total_paid': 199,
        'booked_at': now.toIso8601String(),
        'status': 'confirmed',
        'seat_number': null,
      },
      {
        'user_id': _devUserId,
        'confirmation_code': 'JSXLT7Q',
        'flight_id': f3Id,
        'departure_time': dep3.toIso8601String(),
        'arrival_time': dep3.add(const Duration(hours: 2, minutes: 15)).toIso8601String(),
        'total_paid': 299,
        'booked_at': now.subtract(const Duration(days: 20)).toIso8601String(),
        'status': 'completed',
        'seat_number': 12,
      },
      {
        'user_id': _devUserId,
        'confirmation_code': 'JSX8WXN',
        'flight_id': f4Id,
        'departure_time': dep4.toIso8601String(),
        'arrival_time': dep4.add(const Duration(hours: 2, minutes: 45)).toIso8601String(),
        'total_paid': 349,
        'booked_at': now.subtract(const Duration(days: 45)).toIso8601String(),
        'status': 'completed',
        'seat_number': 4,
      },
    ];

    await _db.from('bookings').insert(rows);

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

  // ── Flight utilities ────────────────────────────────────────────────────────

  Future<void> resetFlightSeats() async {
    await _db.rpc('reset_flight_seats');
  }

  Future<void> setFlightStatus(String flightId, String status) async {
    await _db.from('flights').update({'status': status}).eq('id', flightId);
    // Live Activity push is handled server-side by the flight_status_change
    // Postgres trigger (migration 006), which calls update-live-activity via pg_net.
  }

  // Today's flights (used by status picker).
  Future<List<Map<String, dynamic>>> getFlights() async {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _db
        .from('flights')
        .select('id, route_id, origin_code, dest_code, departure_at, status')
        .gte('departure_at', start.toIso8601String())
        .lt('departure_at', end.toIso8601String())
        .order('departure_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  // Update any subset of a flight's columns.
  Future<void> updateFlight(String id, Map<String, dynamic> fields) async {
    await _db.from('flights').update(fields).eq('id', id);
  }

  // Book a flight for the dev user (1 passenger). Returns confirmation code.
  Future<String> bookFlight(Map<String, dynamic> flight) async {
    final code = _generateCode();
    final booking = await _db.from('bookings').insert({
      'user_id': _devUserId,
      'confirmation_code': code,
      'flight_id': flight['id'],
      'departure_time': flight['departure_at'],
      'arrival_time': flight['arrival_at'],
      'total_paid': (flight['price'] as num).toDouble(),
      'status': 'confirmed',
    }).select().single();

    await _db.from('passengers').insert({
      'booking_id': booking['id'],
      'first_name': 'Alex',
      'last_name': 'Rivera',
    });

    await _db.rpc('decrement_seats', params: {
      'flight_id': flight['id'],
      'count': 1,
    });

    return code;
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return 'JSX${List.generate(4, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  // Next 7 days of flights with full detail (used by flights viewer).
  Future<List<Map<String, dynamic>>> getFlightsFull() async {
    final now = DateTime.now().toUtc();
    final end = now.add(const Duration(days: 7));
    final rows = await _db
        .from('flights')
        .select('id, route_id, origin_code, dest_code, departure_at, arrival_at, aircraft, total_seats, avail_seats, price, status')
        .gte('departure_at', now.toIso8601String())
        .lt('departure_at', end.toIso8601String())
        .order('departure_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  // ── User utilities ──────────────────────────────────────────────────────────

  Future<void> resetUserStats() async {
    await _db
        .from('users')
        .update({'loyalty_points': 12450, 'credit_balance': 250.00})
        .eq('id', _devUserId);
  }

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

  // ── Live activities ─────────────────────────────────────────────────────────

  Future<void> triggerLiveActivity() async {
    final res = await _db.functions.invoke('trigger-live-activity');
    if (res.status != 200) {
      throw Exception('trigger-live-activity returned ${res.status}: ${res.data}');
    }
  }

  Future<void> clearLiveActivities() async {
    await _db.from('live_activities').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static DateTime _routeDep(DateTime nowUtc, int dayOffset, int hour, int minute) {
    final date = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
        .add(Duration(days: dayOffset));
    return date.add(Duration(hours: hour, minutes: minute));
  }

  static String _dateStr(DateTime utc) =>
      '${utc.year}'
      '${utc.month.toString().padLeft(2, '0')}'
      '${utc.day.toString().padLeft(2, '0')}';
}
