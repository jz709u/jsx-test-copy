import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/presentation/providers/flight_results_provider.dart';
import 'package:jsx_app_copy/features/flights/presentation/screens/search_screen.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');
const _las = Airport(code: 'LAS', city: 'Las Vegas', name: 'Harry Reid Intl');

Widget _wrap({List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: SearchScreen()),
    );

List<Override> _overrides({AsyncValue<List<Airport>> airports = const AsyncValue.loading()}) => [
      airportsProvider.overrideWith((ref) async {
        if (airports is AsyncLoading) return Completer<List<Airport>>().future;
        if (airports is AsyncError) throw (airports as AsyncError).error;
        return (airports as AsyncData<List<Airport>>).value;
      }),
    ];

void main() {
  group('SearchScreen', () {
    group('airports loading', () {
      testWidgets('shows app bar title', (tester) async {
        await tester.pumpWidget(_wrap(overrides: _overrides()));
        await tester.pump();
        expect(find.text('Book a Flight'), findsOneWidget);
      });

      testWidgets('search button is disabled with no airports selected', (tester) async {
        await tester.pumpWidget(_wrap(overrides: _overrides()));
        await tester.pump();
        final btn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Search Flights'));
        expect(btn.onPressed, isNull);
      });
    });

    group('airports error', () {
      testWidgets('still renders the search card', (tester) async {
        await tester.pumpWidget(_wrap(
          overrides: _overrides(airports: AsyncValue.error(Exception('network error'), StackTrace.empty)),
        ));
        await tester.pump();
        await tester.pump();
        expect(find.text('Book a Flight'), findsOneWidget);
      });
    });

    group('airports loaded', () {
      final airports = [_dal, _bur, _las];

      testWidgets('shows popular route rows for each airport', (tester) async {
        await tester.pumpWidget(_wrap(overrides: _overrides(airports: AsyncData(airports))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('DAL'), findsWidgets);
        expect(find.text('BUR'), findsWidgets);
      });

      testWidgets('search button is still disabled until from/to are selected', (tester) async {
        await tester.pumpWidget(_wrap(overrides: _overrides(airports: AsyncData(airports))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        final btn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Search Flights'));
        expect(btn.onPressed, isNull);
      });

      testWidgets('round trip toggle is present', (tester) async {
        await tester.pumpWidget(_wrap(overrides: _overrides(airports: AsyncData(airports))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('One Way'), findsOneWidget);
        expect(find.text('Round Trip'), findsOneWidget);
      });
    });
  });
}
