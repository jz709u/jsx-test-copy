import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/airport.dart';

@immutable
class FlightSearchState {
  final Airport? from;
  final Airport? to;
  final DateTime date;
  final int passengers;
  final bool roundTrip;

  const FlightSearchState({
    this.from,
    this.to,
    required this.date,
    this.passengers = 1,
    this.roundTrip = false,
  });

  bool get canSearch => from != null && to != null && from!.code != to!.code;

  FlightSearchState copyWith({
    Airport? from,
    Airport? to,
    DateTime? date,
    int? passengers,
    bool? roundTrip,
    bool clearFrom = false,
    bool clearTo = false,
  }) =>
      FlightSearchState(
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
        date: date ?? this.date,
        passengers: passengers ?? this.passengers,
        roundTrip: roundTrip ?? this.roundTrip,
      );
}

class FlightSearchNotifier extends StateNotifier<FlightSearchState> {
  FlightSearchNotifier() : super(FlightSearchState(date: DateTime.now()));

  void setFrom(Airport airport) => state = state.copyWith(from: airport);
  void setTo(Airport airport) => state = state.copyWith(to: airport);
  void setDate(DateTime date) => state = state.copyWith(date: date);
  void setPassengers(int count) => state = state.copyWith(passengers: count);
  void setRoundTrip(bool value) => state = state.copyWith(roundTrip: value);

  void swap() {
    final tmp = state.from;
    state = state.copyWith(from: state.to, to: tmp, clearFrom: state.to == null, clearTo: tmp == null);
  }
}

final flightSearchProvider =
    StateNotifierProvider<FlightSearchNotifier, FlightSearchState>(
  (_) => FlightSearchNotifier(),
);
