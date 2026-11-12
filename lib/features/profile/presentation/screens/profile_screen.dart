import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/fade_page_route.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../domain/user_profile.dart';
import '../../services/profile_repository.dart';
import '../widgets/password_form_dialog.dart';
import '../widgets/profile_form.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProfile _profile = UserProfile.guest();
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _profile = ref.read(profileRepositoryProvider).getCurrentProfile();
    });
  }

  String _getDisplayName() => _profile.displayName;

  String _getEmail() => _profile.email;

  String _getPhoneNumber() => _profile.phone;

  String _getFormattedRegistrationDate() => _profile.formattedRegistrationDate;

  String _getProviderName() => _profile.authProvider;

  String? _getAvatarUrl() => _localAvatarPath ?? _profile.avatarUrl;

  String _getInitials(String name) => _profile.initials;

  /// Task 4: Pilih Foto Profil Asli (Kamera atau Galeri)
  Future<void> _pickAvatarImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Ubah Foto Profil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryBlue),
                ),
                title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Gunakan kamera ponsel untuk swafoto langsung', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pilih foto yang sudah ada di penyimpanan ponsel', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (_getAvatarUrl() != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Hapus Foto Profil', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  subtitle: const Text('Gunakan inisial nama sebagai avatar bawaan', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() {
                      _localAvatarPath = null;
                    });
                    await ref.read(profileRepositoryProvider).updateAvatar(null);
                    _loadUserData();
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      try {
        final picked = await picker.pickImage(
          source: source,
          maxWidth: 600,
          maxHeight: 600,
          imageQuality: 85,
        );
        if (picked != null) {
          setState(() {
            _localAvatarPath = picked.path;
          });

          await ref.read(profileRepositoryProvider).updateAvatar(picked.path);
          _loadUserData();

          if (mounted) {
            AppSnackBar.showSuccess(context, 'Foto profil berhasil diperbarui!');
          }
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Gagal memilih foto: $e');
        }
      }
    }
  }

  /// Task 3: Ubah Kata Sandi (Change Password)
  Future<void> _changePasswordDialog() async {
    await PasswordFormDialog.show(
      context: context,
      onSubmit: (newPassword) async {
        await ref.read(profileRepositoryProvider).changePassword(newPassword);
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Kata sandi berhasil diperbarui!');
        }
      },
    );
  }

  /// Ubah Profil (Edit Profile)
  Future<void> _editProfileDialog() async {
    await ProfileForm.showAsDialog(
      context: context,
      initialName: _getDisplayName(),
      initialPhone: _getPhoneNumber(),
      onSubmit: (data) async {
        await ref.read(profileRepositoryProvider).updateProfile(
          displayName: data.name,
          phone: data.phone,
        );
        _loadUserData();
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Profil berhasil diperbarui!');
        }
      },
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun SimpanNota?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(profileRepositoryProvider).signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          FadePageRoute(page: const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName();
    final email = _getEmail();
    final phone = _getPhoneNumber();
    final regDate = _getFormattedRegistrationDate();
    final provider = _getProviderName();
    final initials = _getInitials(displayName);
    final avatarUrl = _getAvatarUrl();
    final isEmailProvider = !provider.contains('Google');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Semantics(
            button: true,
            label: 'Ubah profil',
            hint: 'Ketuk untuk mengedit nama pengguna atau nomor telepon',
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah Profil',
              onPressed: _editProfileDialog,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Avatar Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryNavy,
                    AppColors.primaryBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar Circle dengan opsi ganti foto (Task 4)
                  Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: avatarUrl != null
                              ? (avatarUrl.startsWith('http')
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File(avatarUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ))
                              : Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: AppColors.primaryBlue,
                          shape: const CircleBorder(
                            side: BorderSide(color: Colors.white, width: 2),
                          ),
                          elevation: 3,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAvatarImage,
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Badge Provider (Google / Email)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.contains('Google') ? Icons.g_mobiledata_rounded : Icons.mail_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card Informasi Detail Pengguna
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.person_rounded,
                    label: 'Nama Pengguna',
                    value: displayName,
                    showEditHint: true,
                    onTap: _editProfileDialog,
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16, color: isDark ? const Color(0xFF334155) : AppColors.cardBorder),
                  _buildProfileTile(
                    icon: Icons.email_rounded,
                    label: 'Email Terdaftar',
                    value: email,
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16, color: isDark ? const Color(0xFF334155) : AppColors.cardBorder),
                  _buildProfileTile(
                    icon: Icons.phone_rounded,
                    label: 'Nomor Telepon',
                    value: phone,
                    showEditHint: true,
                    onTap: _editProfileDialog,
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16, color: isDark ? const Color(0xFF334155) : AppColors.cardBorder),
                  _buildProfileTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Tanggal Mendaftar',
                    value: regDate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Card Pengaturan Preferensi Tema (Mode Gelap)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? Colors.amber : AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Gelap (Dark Mode)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDark
                                ? 'Tampilan gelap nyaman untuk mata'
                                : 'Tampilan terang default',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: ref.watch(themeModeProvider) == ThemeMode.dark,
                      activeTrackColor: const Color(0xFF38BDF8),
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).setTheme(
                              val ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Banner Pengingat Nomor Telepon jika belum diisi
            if (phone == '-')
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: Colors.amber.shade800, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nomor Telepon Belum Diisi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lengkapi nomor WhatsApp agar bisa menerima notifikasi pengingat garansi.',
                            style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _editProfileDialog,
                      child: const Text('Isi Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Task 3: Tombol Ubah Kata Sandi (jika bukan akun Google)
            if (isEmailProvider) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _changePasswordDialog,
                  icon: const Icon(Icons.lock_reset_rounded, size: 20),
                  label: const Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryNavy,
                    side: const BorderSide(color: AppColors.cardBorder, width: 1.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Tombol Keluar Akun
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String label,
    required String value,
    bool showEditHint = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: value == '-'
                          ? AppColors.textGrey
                          : (isDark ? Colors.white : AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
            if (showEditHint)
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
