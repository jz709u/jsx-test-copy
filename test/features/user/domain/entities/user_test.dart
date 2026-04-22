import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/user/domain/entities/user.dart';

const _base = User(
  id: 'u1',
  firstName: 'Alex',
  lastName: 'Smith',
  email: 'alex@jsx.com',
  phone: '555',
  loyaltyPoints: 0,
  creditBalance: 0,
  memberSince: '2023',
  preferredSeat: 'window',
);

void main() {
  group('User', () {
    test('fullName concatenates first and last name', () {
      expect(_base.fullName, 'Alex Smith');
    });

    test('initials are uppercase first letters of first and last name', () {
      expect(_base.initials, 'AS');
    });

    test('initials work for single-character names', () {
      const u = User(
        id: 'u2', firstName: 'J', lastName: 'K',
        email: '', phone: '', loyaltyPoints: 0, creditBalance: 0,
        memberSince: '', preferredSeat: '',
      );
      expect(u.initials, 'JK');
    });
  });
}
