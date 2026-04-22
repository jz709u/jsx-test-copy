import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/user/data/repositories/mock_user_repository.dart';

void main() {
  late MockUserRepository repo;

  setUp(() => repo = MockUserRepository());

  group('MockUserRepository.getCurrentUser', () {
    test('returns a user with a non-empty id', () async {
      final user = await repo.getCurrentUser();
      expect(user.id, isNotEmpty);
    });

    test('returns a user with first and last name', () async {
      final user = await repo.getCurrentUser();
      expect(user.firstName, isNotEmpty);
      expect(user.lastName, isNotEmpty);
    });

    test('returns a user with positive loyalty points', () async {
      final user = await repo.getCurrentUser();
      expect(user.loyaltyPoints, greaterThan(0));
    });

    test('returns a user with positive credit balance', () async {
      final user = await repo.getCurrentUser();
      expect(user.creditBalance, greaterThan(0));
    });

    test('initials are derived from first and last name', () async {
      final user = await repo.getCurrentUser();
      expect(user.initials, '${user.firstName[0]}${user.lastName[0]}');
    });
  });
}
