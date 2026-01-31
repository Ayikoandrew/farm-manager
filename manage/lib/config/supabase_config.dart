import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Use compile-time env (--dart-define) with fallback to dotenv (local .env file)
  static const _compileTimeUrl = String.fromEnvironment('SUPABASE_URL');
  static const _compileTimeKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  late final String supabaseUrl;
  late final String supabaseAnonKey;

  SupabaseConfig() {
    supabaseUrl = _compileTimeUrl.isNotEmpty
        ? _compileTimeUrl
        : (dotenv.env['SUPABASE_URL'] ?? '');
    supabaseAnonKey = _compileTimeKey.isNotEmpty
        ? _compileTimeKey
        : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

    // Debug: log which source is being used
    debugPrint(
      'Supabase URL source: ${_compileTimeUrl.isNotEmpty ? "compile-time" : "dotenv"}',
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
