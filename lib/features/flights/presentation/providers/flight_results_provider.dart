import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/debug/backend_mode.dart';
import '../../data/repositories/mock_flight_repository.dart';
import '../../data/repositories/supabase_flight_repository.dart';
import '../../domain/entities/airport.dart';
import '../../domain/entities/flight.dart';
import '../../domain/repositories/flight_repository.dart';
import '../../domain/use_cases/search_flights.dart';

final flightRepositoryProvider = Provider<FlightRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return MockFlightRepository();
  return SupabaseFlightRepository(client);
});

final searchFlightsUseCaseProvider = Provider<SearchFlights>(
  (ref) => SearchFlights(ref.watch(flightRepositoryProvider)),
);

final airportsProvider = FutureProvider<List<Airport>>((ref) {
  return ref.watch(flightRepositoryProvider).getAirports();
});

@immutable
class FlightSearchParams {
  final String fromCode;
  final String toCode;
  final DateTime date;

  const FlightSearchParams({
    required this.fromCode,
    required this.toCode,
    required this.date,
  });

  @override
  bool operator ==(Object other) =>
      other is FlightSearchParams &&
      other.fromCode == fromCode &&
      other.toCode == toCode &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day;

  @override
  int get hashCode =>
      Object.hash(fromCode, toCode, '${date.year}-${date.month}-${date.day}');
}

final flightResultsProvider =
    FutureProvider.family<List<Flight>, FlightSearchParams>((ref, params) async {
  final airports = await ref.watch(airportsProvider.future);
  final from = airports.firstWhere((a) => a.code == params.fromCode);
  final to = airports.firstWhere((a) => a.code == params.toCode);
  return ref.watch(searchFlightsUseCaseProvider).execute(
        from: from,
        to: to,
        date: params.date,
      );
});
