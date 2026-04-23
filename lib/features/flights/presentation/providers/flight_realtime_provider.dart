import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/debug/backend_mode.dart';

/// Emits whenever any row in the flights table is updated.
/// bookingsProvider watches this so it re-fetches (and refreshes the widget)
/// whenever a flight status changes — including server-side trigger updates.
final flightStatusChangesProvider = StreamProvider<void>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return;

  final controller = StreamController<void>();

  final channel = client
      .channel('public:flights:status')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'flights',
        callback: (_) => controller.add(null),
      )
      .subscribe();

  ref.onDispose(() {
    controller.close();
    client.removeChannel(channel);
  });

  yield* controller.stream;
});
