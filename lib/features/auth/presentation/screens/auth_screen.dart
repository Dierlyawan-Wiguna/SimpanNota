import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/navigation/fade_page_route.dart';
import '../../../../core/widgets/customer_service_button.dart';
import '../../../receipts/presentation/screens/home_screen.dart';

/// Screen autentikasi biometrik/PIN (local_auth)
/// Pengguna wajib melakukan pemindaian biometrik atau memasukkan PIN perangkat
/// sebelum diizinkan masuk ke Dashboard (HomeScreen).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkDeviceSupportAndAuthenticate();
  }

  Future<void> _checkDeviceSupportAndAuthenticate() async {
    try {
      // Jalankan autentikasi otomatis saat layar terbuka
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticate();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memeriksa dukungan biometrik: $e';
        });
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final isSupported =
          await _auth.isDeviceSupported() || await _auth.canCheckBiometrics;
      if (!isSupported) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage =
              'Perangkat ini tidak mendukung fitur biometrik/PIN keamanan.';
        });
        return;
      }

      // Memulai proses autentikasi biometrik / PIN
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason:
            'Pindai biometrik atau masukkan PIN untuk masuk ke SimpanNota',
        biometricOnly: false, // Memungkinkan fallback ke PIN/Pola perangkat
      );

      if (!mounted) return;

      setState(() {
        _isAuthenticating = false;
      });

      if (didAuthenticate) {
        // Autentikasi Sukses: Masuk ke Dashboard (HomeScreen) dengan animasi Fade
        Navigator.pushReplacement(
          context,
          FadePageRoute(page: const HomeScreen()),
        );
      } else {
        // Pengguna membatalkan proses pemindaian (cancel)
        setState(() {
          _errorMessage = 'Autentikasi dibatalkan oleh pengguna. Silakan pindai ulang untuk masuk.';
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
      });

      final code = e.code.toLowerCase();
      // Penanganan berbagai skenario error dari local_auth
      if (code.contains('notavailable')) {
        setState(() {
          _errorMessage = 'Fitur biometrik tidak tersedia atau dinonaktifkan pada perangkat ini.';
        });
      } else if (code.contains('notenrolled')) {
        setState(() {
          _errorMessage = 'Belum ada sidik jari/PIN yang terdaftar di perangkat. Silakan atur di pengaturan HP.';
        });
      } else if (code.contains('passcodenotset')) {
        setState(() {
          _errorMessage =
              'Kunci layar (PIN/Pola/Sandi) belum diatur pada perangkat ini.';
        });
      } else if (code.contains('lockedout')) {
        setState(() {
          _errorMessage = 'Terlalu banyak percobaan gagal. Silakan coba lagi beberapa saat lagi.';
        });
      } else {
        setState(() {
          _errorMessage = 'Error autentikasi: ${e.message ?? e.code}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Terjadi kesalahan sistem: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              28.0,
              32.0,
              28.0,
              32.0 + keyboardBottomInset,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon Kunci / Biometrik
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: _isAuthenticating
                        ? const SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(strokeWidth: 4),
                          )
                        : const Icon(
                            Icons.fingerprint_rounded,
                            size: 80,
                            color: AppColors.primaryBlue,
                          ),
                  ),
                ),
                const SizedBox(height: 36),

                // Judul dan Keterangan
                const Text(
                  'Autentikasi Keamanan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isAuthenticating ? 'Menunggu pemindaian biometrik / PIN...' : 'Wajib melakukan verifikasi biometrik (sidik jari/wajah) atau PIN sebelum mengakses Dashboard SimpanNota.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Pesan Error jika device tidak mendukung atau pengguna cancel
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tombol Pindai Biometrik / PIN
                Semantics(
                  button: true,
                  label: _isAuthenticating
                      ? 'Sedang memindai biometrik atau PIN'
                      : 'Pindai biometrik atau PIN',
                  hint: 'Ketuk untuk memindai sidik jari atau memasukkan PIN layar perangkat',
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(
                      _isAuthenticating
                          ? 'Sedang Memindai...'
                          : 'Pindai Biometrik / PIN',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Kembali / Ganti Akun
                Semantics(
                  button: true,
                  label: 'Ganti akun atau halaman login',
                  hint: 'Ketuk untuk membuka halaman selamat datang dan login akun lain',
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        FadePageRoute(page: const WelcomeScreen()),
                      );
                    },
                    child: const Text(
                      'Ganti Akun / Halaman Login',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24.0,
            28.0,
            24.0,
            28.0 + keyboardBottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Logo & Hero Badge SimpanNota
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0F172A),
                              Color(0xFF1E3A8A),
                              Color(0xFF2563EB),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Teks Sambutan
              const Text(
                'Welcome to SimpanNota',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Solusi cerdas digitalisasi bukti transaksi, arsip struk belanja, dan pemantauan masa aktif garansi barang Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // Kartu Fitur Singkat
              _buildFeatureItem(
                icon: Icons.document_scanner_outlined,
                iconColor: AppColors.primaryBlue,
                bgColor: AppColors.lightBlue,
                title: 'Digitalisasi Nota Praktis',
                description: 'Ambil foto nota fisik agar aman tersimpan dan tidak luntur.',
              ),
              const SizedBox(height: 10),
              _buildFeatureItem(
                icon: Icons.verified_user_outlined,
                iconColor: AppColors.statusActive,
                bgColor: AppColors.statusActiveBg,
                title: 'Pantau Masa Garansi',
                description: 'Ketahui nota yang masih aktif, segera berakhir, atau kedaluwarsa.',
              ),
              const SizedBox(height: 10),
              _buildFeatureItem(
                icon: Icons.cloud_done_outlined,
                iconColor: AppColors.primaryTeal,
                bgColor: AppColors.lightBlue,
                title: 'Penyimpanan Akun & Cloud',
                description: 'Arsip nota tersimpan rapi dan tersinkronisasi aman ke akun Anda.',
              ),

              const SizedBox(height: 32),

              // Tombol 'Mulai' yang Lebar (Langsung menuju Halaman Login)
              Semantics(
                button: true,
                label: 'Tombol Mulai aplikasi',
                hint: 'Ketuk untuk melanjutkan ke halaman login akun',
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        FadePageRoute(page: const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: AppColors.primaryBlue.withValues(
                        alpha: 0.35,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mulai',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (SupabaseConstants.isConfigured) {
      try {
        _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          final AuthChangeEvent event = data.event;
          if (event == AuthChangeEvent.signedIn && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Login Google berhasil! Selamat datang.'),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              FadePageRoute(page: const HomeScreen()),
              (route) => false,
            );
          }
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email harus diisi.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Email harus diisi.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password harus diisi.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Password harus diisi.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!SupabaseConstants.isConfigured) {
      // Fallback untuk testing jika Supabase belum terhubung
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Login berhasil! (Mode Offline/Testing)'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        FadePageRoute(page: const HomeScreen()),
        (route) => false,
      );
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Login berhasil! Selamat datang kembali.'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          FadePageRoute(page: const HomeScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      String userMessage = e.message;
      if (msg.contains('invalid login credentials')) {
        userMessage = 'Email atau password salah.';
      } else if (msg.contains('email not confirmed')) {
        userMessage =
            'Email belum dikonfirmasi. Periksa kotak masuk email Anda.';
      }
      setState(() => _errorMessage = userMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(userMessage)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final err = 'Gagal masuk: $e';
      setState(() => _errorMessage = err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(err)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    if (!SupabaseConstants.isConfigured) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Supabase belum dikonfigurasi. Periksa supabase_constants.dart.'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      final success = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.simpannota://login-callback',
      );
      if (!success && mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal login Google: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool isSending = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Lupa Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan email akun SimpanNota Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: resetEmailController.text.isEmpty,
                    decoration: InputDecoration(
                      labelText: 'Alamat Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  if (dialogError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        dialogError!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            setDialogState(() {
                              dialogError = 'Masukkan alamat email yang valid.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSending = true;
                            dialogError = null;
                          });

                          try {
                            if (SupabaseConstants.isConfigured) {
                              await Supabase.instance.client.auth.resetPasswordForEmail(
                                email,
                                redirectTo: kIsWeb ? null : 'io.supabase.simpannota://login-callback',
                              );
                            }

                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.mark_email_read_rounded, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Tautan reset password telah dikirim ke $email. Periksa kotak masuk/spam.'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSending = false;
                              dialogError = 'Gagal mengirim email: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Kirim Tautan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'Kembali ke halaman sebelumnya',
          child: const BackButton(color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24.0,
            24.0,
            24.0,
            24.0 + keyboardBottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Selamat Datang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Masuk ke akun SimpanNota Anda untuk mengelola nota dan garansi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 36),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Semantics(
                textField: true,
                label: 'Kolom input email',
                hint: 'Ketik alamat email Anda',
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    filled: true,
                    fillColor: AppColors.lightBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Semantics(
                textField: true,
                label: 'Kolom input kata sandi',
                hint: 'Ketik kata sandi akun',
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primaryBlue,
                    ),
                    suffixIcon: Semantics(
                      button: true,
                      label: _isPasswordVisible
                          ? 'Sembunyikan kata sandi'
                          : 'Tampilkan kata sandi',
                      child: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          );
                        },
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.lightBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Tombol Lupa Password
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  button: true,
                  label: 'Tombol lupa password',
                  hint: 'Ketuk untuk mengatur ulang kata sandi akun Anda',
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Semantics(
                button: true,
                label: 'Tombol masuk akun',
                hint: 'Ketuk untuk memverifikasi akun dan masuk ke aplikasi',
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Masuk (Sign In)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider "atau masuk dengan"
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.cardBorder)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'atau masuk dengan',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.cardBorder)),
                ],
              ),
              const SizedBox(height: 18),

              // Tombol Google Login
              Semantics(
                button: true,
                label: 'Tombol masuk dengan Google',
                hint: 'Ketuk untuk masuk menggunakan akun Google Anda',
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) => Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                            width: 22,
                            height: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Lanjutkan dengan Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Semantics(
                  button: true,
                  label: 'Tautan buat akun baru',
                  hint: 'Ketuk untuk berpindah ke halaman pendaftaran',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        FadePageRoute(page: const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Belum punya akun? Buat akun baru',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Customer Service: "Butuh Bantuan?"
              const Center(
                child: CustomerServiceButton(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (SupabaseConstants.isConfigured) {
      try {
        _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          final AuthChangeEvent event = data.event;
          if (event == AuthChangeEvent.signedIn && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Registrasi Google berhasil! Selamat datang.'),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              FadePageRoute(page: const HomeScreen()),
              (route) => false,
            );
          }
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    var phoneInput = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Nama lengkap harus diisi.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Nama lengkap harus diisi.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email harus diisi.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Email harus diisi.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password minimal 6 karakter.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Password minimal 6 karakter.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Konfirmasi password tidak cocok.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Normalisasi nomor telepon
    phoneInput = phoneInput.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneInput.startsWith('0')) {
      phoneInput = phoneInput.substring(1);
    } else if (phoneInput.startsWith('62')) {
      phoneInput = phoneInput.substring(2);
    }
    final formattedPhone = phoneInput.isNotEmpty ? '+62$phoneInput' : null;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!SupabaseConstants.isConfigured) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Akun telah dibuat. Silakan masuk ke akun Anda.')),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        FadePageRoute(page: const LoginScreen()),
        (route) => false,
      );
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'name': name,
          if (formattedPhone != null) 'phone': formattedPhone,
        },
      );

      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Akun telah dibuat. Silakan masuk ke akun Anda.')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          FadePageRoute(page: const LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      String userMessage = e.message;
      if (msg.contains('already registered') ||
          msg.contains('user already exists')) {
        userMessage = 'Email ini sudah terdaftar. Silakan langsung masuk.';
      }
      setState(() => _errorMessage = userMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(userMessage)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final err = 'Gagal mendaftar: $e';
      setState(() => _errorMessage = err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(err)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    if (!SupabaseConstants.isConfigured) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Supabase belum dikonfigurasi. Periksa supabase_constants.dart.'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      final success = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.simpannota://login-callback',
      );
      if (!success && mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal login Google: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'Kembali ke halaman sebelumnya',
          child: const BackButton(color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24.0,
            24.0,
            24.0,
            24.0 + keyboardBottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Buat Akun Baru',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Daftar akun untuk mencatat dan mengamankan nota belanja serta garansi Anda di cloud.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 36),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Semantics(
                textField: true,
                label: 'Kolom input nama lengkap',
                hint: 'Ketik nama lengkap Anda',
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Nama Lengkap',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.primaryBlue,
                    ),
                    filled: true,
                    fillColor: AppColors.lightBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Semantics(
                textField: true,
                label: 'Kolom input nomor telepon atau WhatsApp',
                hint: 'Ketik nomor telepon WhatsApp Anda',
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '81234567890 (WhatsApp)',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '+62',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            height: 20,
                            child: VerticalDivider(
                              color: AppColors.cardBorder,
                              width: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.lightBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Semantics(
                textField: true,
                label: 'Kolom input email',
                hint: 'Ketik alamat email Anda',
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    filled: true,
                    fillColor: AppColors.lightBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Semantics(
                textField: true,
                label: 'Kolom input kata sandi baru',
                hint: 'Ketik kata sandi minimal enam karakter',
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password (min. 6 karakter)',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primaryBlue,
                    ),
                    suffixIcon: Semantics(
                      button: true,
                      label: _isPasswordVisible
                          ? 'Sembunyikan kata sandi'
                          : 'Tampilkan kata sandi',
                      child: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          );
                        },
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.lightBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Semantics(
                textField: true,
                label: 'Kolom input konfirmasi kata sandi',
                hint: 'Ketik ulang kata sandi yang sama persis',
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Konfirmasi Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primaryBlue,
                    ),
                    filled: true,
                    fillColor: AppColors.lightBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Semantics(
                button: true,
                label: 'Tombol daftar akun',
                hint: 'Ketuk untuk menyelesaikan registrasi akun baru',
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Daftar (Sign Up)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider "atau daftar dengan"
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.cardBorder)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'atau daftar dengan',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.cardBorder)),
                ],
              ),
              const SizedBox(height: 18),

              // Tombol Google Register
              Semantics(
                button: true,
                label: 'Tombol daftar dengan Google',
                hint: 'Ketuk untuk mendaftar akun menggunakan akun Google Anda',
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) => Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                            width: 22,
                            height: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Daftar dengan Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Semantics(
                  button: true,
                  label: 'Tautan sudah punya akun',
                  hint: 'Ketuk untuk kembali ke halaman login',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        FadePageRoute(page: const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Sudah punya akun? Masuk di sini',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
