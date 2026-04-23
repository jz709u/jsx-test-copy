import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum BackendMode { mock, local, prod }

extension BackendModeLabel on BackendMode {
  String get label {
    switch (this) {
      case BackendMode.mock:  return 'Mock (offline)';
      case BackendMode.local: return 'Local Supabase';
      case BackendMode.prod:  return 'Production';
    }
  }
}

// Local Supabase constants (matches supabase start defaults).
const localSupabaseUrl     = 'http://127.0.0.1:54321';
const localSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9'
    '.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

final backendModeProvider = StateProvider<BackendMode>((_) => BackendMode.prod);

// Returns the correct SupabaseClient for the active mode (null for mock).
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  switch (ref.watch(backendModeProvider)) {
    case BackendMode.mock:
      return null;
    case BackendMode.local:
      return SupabaseClient(localSupabaseUrl, localSupabaseAnonKey);
    case BackendMode.prod:
      return Supabase.instance.client;
  }
});
