import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/debug/backend_mode.dart';
import '../../data/repositories/mock_user_repository.dart';
import '../../data/repositories/supabase_user_repository.dart';
import '../../domain/entities/user.dart' as JSXUser;
import '../../domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return MockUserRepository();
  return SupabaseUserRepository(client);
});

final currentUserProvider = FutureProvider<JSXUser.User>(
    (ref) => ref.watch(userRepositoryProvider).getCurrentUser());
