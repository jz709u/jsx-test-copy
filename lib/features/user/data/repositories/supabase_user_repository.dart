import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../sources/supabase_user_data_source.dart';

class SupabaseUserRepository implements UserRepository {
  final SupabaseUserDataSource _source;
  SupabaseUserRepository(this._source);

  @override
  Future<User> getCurrentUser() => _source.getCurrentUser();
}
