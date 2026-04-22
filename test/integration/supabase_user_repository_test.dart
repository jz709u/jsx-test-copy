/// Requires local Supabase: supabase start
/// Run: flutter test test/integration/supabase_user_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jsx_app_copy/features/user/data/repositories/supabase_user_repository.dart';
import 'local_supabase.dart';

void main() {
  late SupabaseClient client;
  late SupabaseUserRepository repo;

  setUpAll(() => client = makeClient());
  tearDownAll(() => client.dispose());
  setUp(() => repo = SupabaseUserRepository(client));

  group('SupabaseUserRepository', () {
    test('getCurrentUser returns the dev user', () async {
      final user = await repo.getCurrentUser();
      expect(user.id, 'a0000000-0000-0000-0000-000000000001');
      expect(user.firstName, isNotEmpty);
      expect(user.lastName, isNotEmpty);
      expect(user.email, isNotEmpty);
    });

    test('loyalty points and credit balance are non-negative', () async {
      final user = await repo.getCurrentUser();
      expect(user.loyaltyPoints, isNonNegative);
      expect(user.creditBalance, isNonNegative);
    });

    test('initials are derived from first and last name', () async {
      final user = await repo.getCurrentUser();
      expect(user.initials, '${user.firstName[0]}${user.lastName[0]}');
    });
  });
}
