import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as app_user;
import '../../../../core/supabase/supabase_config.dart';

class SupabaseUserDataSource {
  final SupabaseClient _client;
  SupabaseUserDataSource(this._client);

  Future<app_user.User> getCurrentUser() async {
    final row = await _client
        .from('users')
        .select()
        .eq('id', SupabaseConfig.devUserId)
        .single();

    return app_user.User(
      id: row['id'],
      firstName: row['first_name'],
      lastName: row['last_name'],
      email: row['email'],
      phone: row['phone'] ?? '',
      loyaltyPoints: row['loyalty_points'] ?? 0,
      creditBalance: (row['credit_balance'] as num?)?.toDouble() ?? 0,
      memberSince: row['member_since'] ?? '',
      knownTravelerNumber: row['known_traveler_number'],
      preferredSeat: row['preferred_seat'] ?? 'Window',
    );
  }
}
