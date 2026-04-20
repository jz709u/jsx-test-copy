import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/mock_user_repository.dart';
import '../../data/sources/user_mock_data_source.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (_) => MockUserRepository(UserMockDataSource()),
);

final currentUserProvider = FutureProvider<User>((ref) {
  return ref.watch(userRepositoryProvider).getCurrentUser();
});
