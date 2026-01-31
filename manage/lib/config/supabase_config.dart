import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/env_helper.dart';

class SupabaseConfig {
  late final String supabaseUrl;
  late final String supabaseAnonKey;

  SupabaseConfig() {
    supabaseUrl = EnvHelper.getOrDefault('SUPABASE_URL', '');
    supabaseAnonKey = EnvHelper.getOrDefault('SUPABASE_ANON_KEY', '');

    // Debug: log which source is being used
    debugPrint(
      'Supabase URL source: ${EnvHelper.isDotenvInitialized ? "dotenv" : "compile-time"}',
    );
    debugPrint(
      'Supabase URL: ${supabaseUrl.isNotEmpty ? "${supabaseUrl.substring(0, 20)}..." : "EMPTY!"}',
    );
  }

  Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase configuration missing! '
        'URL empty: ${supabaseUrl.isEmpty}, Key empty: ${supabaseAnonKey.isEmpty}',
      );
    }

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
