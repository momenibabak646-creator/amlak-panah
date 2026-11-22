import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  // Supabase publishable keys are designed for use in client applications.
  // Access to rows and storage is controlled by database RLS policies.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jxvvafpjrfbyrrjaswvu.supabase.co',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_fsTjyACyWwq_WvzGLyKcjg_IRloA8-6',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static Future<void> initialize() async {
    if (hasSupabase) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
    }
  }
}
