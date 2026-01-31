import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Use compile-time env (--dart-define) with fallback to dotenv (local .env file)
  final String supabaseUrl = const String.fromEnvironment('SUPABASE_URL').isNotEmpty
      ? const String.fromEnvironment('SUPABASE_URL')
      : (dotenv.env['SUPABASE_URL'] ?? '');
  
  final String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
