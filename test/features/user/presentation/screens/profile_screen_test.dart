import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/user/domain/entities/user.dart';
import 'package:jsx_app_copy/features/user/presentation/providers/user_provider.dart';
import 'package:jsx_app_copy/features/user/presentation/screens/profile_screen.dart';

const _user = User(
  id: 'u1',
  firstName: 'Alex',
  lastName: 'Smith',
  email: 'alex@jsx.com',
  phone: '5551234567',
  loyaltyPoints: 1350,
  creditBalance: 75,
  memberSince: '2023',
  preferredSeat: 'window',
);

Widget _wrap({AsyncValue<User> user = const AsyncValue.loading()}) => ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) async {
          if (user is AsyncLoading) return Completer<User>().future;
          if (user is AsyncError) throw (user as AsyncError).error;
          return (user as AsyncData<User>).value;
        }),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );

void main() {
  group('ProfileScreen', () {
    group('loading', () {
      testWidgets('shows spinner', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('error', () {
      testWidgets('shows error message', (tester) async {
        await tester.pumpWidget(_wrap(
          user: AsyncValue.error(Exception('unauthorized'), StackTrace.empty),
        ));
        await tester.pump();
        await tester.pump();
        expect(find.textContaining('unauthorized'), findsOneWidget);
      });
    });

    group('with data', () {
      testWidgets('shows Profile in app bar', (tester) async {
        await tester.pumpWidget(_wrap(user: const AsyncData(_user)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('Profile'), findsOneWidget);
      });

      testWidgets('shows full name', (tester) async {
        await tester.pumpWidget(_wrap(user: const AsyncData(_user)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('Alex Smith'), findsOneWidget);
      });

      testWidgets('shows email', (tester) async {
        await tester.pumpWidget(_wrap(user: const AsyncData(_user)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('alex@jsx.com'), findsOneWidget);
      });

      testWidgets('shows loyalty points', (tester) async {
        await tester.pumpWidget(_wrap(user: const AsyncData(_user)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('1350'), findsOneWidget);
      });

      testWidgets('shows credit balance', (tester) async {
        await tester.pumpWidget(_wrap(user: const AsyncData(_user)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.textContaining('75'), findsWidgets);
      });
    });
  });
}
