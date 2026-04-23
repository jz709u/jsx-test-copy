import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/debug/backend_mode.dart';

/// Emits an incrementing counter whenever any flights row is updated.
/// Using int (not void) so Riverpod detects a value change and re-runs
/// any provider watching this.
final flightStatusChangesProvider = StreamProvider<int>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return;

  final controller = StreamController<int>();
  var counter = 0;

  final channel = client
      .channel('public:flights:status')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'flights',
        callback: (_) => controller.add(counter++),
      )
      .subscribe();

  ref.onDispose(() {
    controller.close();
    client.removeChannel(channel);
  });

  yield* controller.stream;
});

/// Ticks every minute. Widgets watching this will rebuild their countdown
/// display without needing a network round-trip.
final minuteTickerProvider = StreamProvider<int>((ref) async* {
  var tick = 0;
  // Align to the next whole minute, then tick every 60 s.
  final now = DateTime.now();
  final msUntilNextMinute =
      (60 - now.second) * 1000 - now.millisecond;
  await Future.delayed(Duration(milliseconds: msUntilNextMinute));
  yield tick++;
  yield* Stream.periodic(const Duration(minutes: 1), (_) => tick++);
});
