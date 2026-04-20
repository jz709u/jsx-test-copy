import '../../domain/entities/user.dart';

class UserMockDataSource {
  Future<User> getCurrentUser() async => const User(
        id: 'usr_001',
        firstName: 'Alex',
        lastName: 'Rivera',
        email: 'alex.rivera@email.com',
        phone: '+1 (555) 234-5678',
        loyaltyPoints: 4820,
        creditBalance: 241.00,
        memberSince: 'March 2023',
        knownTravelerNumber: 'KTN-8821-4490',
        preferredSeat: 'Window',
      );
}
