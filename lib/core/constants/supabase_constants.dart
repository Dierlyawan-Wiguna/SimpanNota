class SupabaseConstants {
  SupabaseConstants._();

  /// Project URL dari dashboard Supabase Anda
  static const String supabaseUrl = 'https://sbbnasdkpmrqkotedsqj.supabase.co';

  /// Project Publishable / Anon API Key dari dashboard Supabase Anda
  static const String supabaseAnonKey =
      'sb_publishable_vEcSzEsO7bEsY-NzKYehVA_hWlCQd7k';

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
