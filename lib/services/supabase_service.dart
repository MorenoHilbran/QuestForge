import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _initialized = false;

  /// Initialize Supabase using values from dotenv or compile-time constants.
  /// Call this before runApp.
  static Future<void> init() async {
    if (_initialized) return;

    // Try dotenv first, then fall back to compile-time constants (for web)
    String? url;
    String? anonKey;
    bool debug = false;

    try {
      url = dotenv.env['SUPABASE_URL'];
      anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      debug = (dotenv.env['SUPABASE_DEBUG'] ?? 'false').toLowerCase() == 'true';
    } catch (e) {
      // dotenv not loaded, try compile-time constants
      if (kDebugMode) debugPrint('Using compile-time environment variables');
    }

    // Fallback to compile-time constants if dotenv didn't work
    url ??= const String.fromEnvironment('SUPABASE_URL');
    anonKey ??= const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️  Supabase env vars not found. App will run in offline mode.');
        debugPrint('For mobile/desktop: Add .env file with SUPABASE_URL and SUPABASE_ANON_KEY');
        debugPrint('For web: Run with --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
      }
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: debug,
    );

    _initialized = true;
    if (kDebugMode) debugPrint('✅ Supabase initialized successfully');
  }

  /// Access Supabase client. Throws if Supabase not initialized.
  static SupabaseClient get client => Supabase.instance.client;

  /// Helper to check if Supabase is available in runtime.
  static bool get available => _initialized;
}
