class SupabaseConstants {
  SupabaseConstants._();

  /// Project URL dari dashboard Supabase Anda.
  /// Disarankan disuplai via --dart-define-from-file=.env atau --dart-define=SUPABASE_URL=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL_HERE',
  );

  /// Project Publishable / Anon API Key dari dashboard Supabase Anda.
  /// Disarankan disuplai via --dart-define-from-file=.env atau --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE',
  );

  /// Helper untuk mengecek apakah URL dan Anon Key sudah diisi oleh pengguna
  static bool get isConfigured {
    final uri = Uri.tryParse(supabaseUrl);
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains('YOUR_SUPABASE_URL_HERE') &&
        !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY_HERE') &&
        uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty;
  }
}
