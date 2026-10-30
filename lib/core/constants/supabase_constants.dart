class SupabaseConstants {
  SupabaseConstants._();

  /// Project URL dari dashboard Supabase Anda
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';

  /// Project Publishable / Anon API Key dari dashboard Supabase Anda
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

  /// Helper untuk mengecek apakah URL dan Anon Key sudah diisi oleh pengguna
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains('YOUR_SUPABASE_URL_HERE') &&
        !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY_HERE') &&
        Uri.tryParse(supabaseUrl)?.hasAbsolutePath == true;
  }
}
