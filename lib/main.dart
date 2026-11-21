import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/supabase_constants.dart';
import 'core/services/app_logger.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global error catching untuk Flutter widget tree / UI errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.fatal(
        'FLUTTER_ERROR',
        details.exceptionAsString(),
        details.exception,
        details.stack,
      );
    };

    // Platform dispatcher error catching untuk asynchronous & platform-level errors
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.fatal(
        'PLATFORM_ERROR',
        error.toString(),
        error,
        stack,
      );
      return true;
    };

    AppLogger.info('APP', 'Memulai inisialisasi aplikasi SimpanNota (Release Candidate)...');

    await initializeDateFormatting('id_ID', null);
    await NotificationService().init();

    if (SupabaseConstants.isConfigured) {
      try {
        await Supabase.initialize(
          url: SupabaseConstants.supabaseUrl,
          publishableKey: SupabaseConstants.supabaseAnonKey,
        );
        AppLogger.info('SUPABASE', 'Supabase berhasil diinisialisasi.');
      } catch (e, stack) {
        AppLogger.error('SUPABASE', 'Gagal menginisialisasi Supabase: $e', e, stack);
      }
    } else {
      AppLogger.warning(
        'SUPABASE',
        'Supabase belum dikonfigurasi. Menggunakan penyimpanan offline SQLite.',
      );
    }

    runApp(const ProviderScope(child: App()));
  }, (error, stack) {
    AppLogger.fatal('ZONE_ERROR', error.toString(), error, stack);
  });
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'SimpanNota',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            shadowColor: AppColors.primaryBlue.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkSurface,
        dividerColor: AppColors.darkBorder,
        cardTheme: const CardThemeData(
          color: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.dark,
          primary: const Color(0xFF38BDF8),
          surface: AppColors.darkSurface,
          surfaceContainer: AppColors.darkSurface,
          surfaceContainerLow: AppColors.darkSurface,
          surfaceContainerHigh: const Color(0xFF334155),
          onSurface: Colors.white,
          outline: AppColors.darkBorder,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      // Initial route: Splash Screen -> Welcome Screen -> AuthScreen (Login) -> HomeScreen
      home: const SplashScreen(),
    );
  }
}
