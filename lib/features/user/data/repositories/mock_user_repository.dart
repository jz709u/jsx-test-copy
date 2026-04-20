import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../sources/user_mock_data_source.dart';

class MockUserRepository implements UserRepository {
  final UserMockDataSource _source;
  const MockUserRepository(this._source);

  @override
  Future<User> getCurrentUser() => _source.getCurrentUser();
}
