import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_user_repository.dart';
import '../../data/sources/supabase_user_data_source.dart';
import '../../domain/entities/user.dart' as JSXUser;
import '../../domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (_) => SupabaseUserRepository(
    SupabaseUserDataSource(Supabase.instance.client),
  ),
);

final currentUserProvider = FutureProvider<JSXUser.User>(
    (ref) => ref.watch(userRepositoryProvider).getCurrentUser());
