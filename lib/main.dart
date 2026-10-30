import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/supabase_constants.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService().init();

  if (SupabaseConstants.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        publishableKey: SupabaseConstants.supabaseAnonKey,
      );
      debugPrint('Supabase berhasil diinisialisasi.');
    } catch (e) {
      debugPrint('Gagal menginisialisasi Supabase: $e');
    }
  } else {
    debugPrint(
      'PERINGATAN: Supabase belum dikonfigurasi. Silakan isi supabaseUrl & supabaseAnonKey di lib/core/constants/supabase_constants.dart.',
    );
  }

  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  Widget _getInitialScreen() {
    if (SupabaseConstants.isConfigured) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          // Pengguna sudah pernah login: verifikasi biometrik / PIN HP untuk buka cepat
          return const AuthScreen();
        } else {
          // Pengguna belum login: arahkan ke halaman Selamat Datang / Login
          return const WelcomeScreen();
        }
      } catch (_) {
        return const WelcomeScreen();
      }
    }
    return const AuthScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimpanNota',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
      ),
      home: _getInitialScreen(),
    );
  }
}
