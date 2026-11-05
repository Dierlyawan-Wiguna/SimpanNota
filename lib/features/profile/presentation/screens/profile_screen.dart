import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/navigation/fade_page_route.dart';
import '../../../auth/presentation/screens/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (SupabaseConstants.isConfigured) {
      try {
        setState(() {
          _currentUser = Supabase.instance.client.auth.currentUser;
        });
      } catch (_) {}
    }
  }

  String _getDisplayName() {
    if (_currentUser == null) return 'Pengguna Tamu';
    final metadata = _currentUser!.userMetadata;
    final fullName = metadata?['full_name'] ?? metadata?['name'] ?? metadata?['display_name'];
    if (fullName != null && fullName.toString().trim().isNotEmpty) {
      return fullName.toString().trim();
    }
    if (_currentUser!.email != null && _currentUser!.email!.isNotEmpty) {
      return _currentUser!.email!.split('@').first;
    }
    return 'Pengguna SimpanNota';
  }

  String _getEmail() {
    if (_currentUser == null) return 'tamu@simpannota.local';
    return _currentUser!.email ?? '-';
  }

  String _getPhoneNumber() {
    if (_currentUser == null) return '-';
    // Cek kolom phone resmi auth atau di userMetadata
    final phone = _currentUser!.phone;
    if (phone != null && phone.isNotEmpty) return phone;
    final metaPhone = _currentUser!.userMetadata?['phone'];
    if (metaPhone != null && metaPhone.toString().isNotEmpty) {
      return metaPhone.toString();
    }
    return '-';
  }

  String _getFormattedRegistrationDate() {
    if (_currentUser == null) {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
    }
    try {
      final createdAtStr = _currentUser!.createdAt;
      final dt = DateTime.parse(createdAtStr).toLocal();
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return '-';
    }
  }

  String _getProviderName() {
    if (_currentUser == null) return 'Offline';
    final appMeta = _currentUser!.appMetadata;
    final provider = appMeta['provider'] as String? ?? 'email';
    if (provider.toLowerCase() == 'google') return 'Google Account';
    return 'Email & Kata Sandi';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Future<void> _editProfileDialog() async {
    final nameController = TextEditingController(text: _getDisplayName());
    String currentPhone = _getPhoneNumber();
    if (currentPhone == '-') currentPhone = '';
    // Hapus awalan +62 jika ada untuk memudahkan input user
    if (currentPhone.startsWith('+62')) {
      currentPhone = currentPhone.substring(3);
    } else if (currentPhone.startsWith('62')) {
      currentPhone = currentPhone.substring(2);
    } else if (currentPhone.startsWith('0')) {
      currentPhone = currentPhone.substring(1);
    }
    final phoneController = TextEditingController(text: currentPhone);
    String? dialogError;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppColors.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Ubah Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Pengguna',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Nama lengkap Anda',
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryBlue),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nomor Telepon (WhatsApp)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '81234567890',
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+62',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(width: 6),
                              SizedBox(
                                height: 20,
                                child: VerticalDivider(color: AppColors.cardBorder, width: 1),
                              ),
                            ],
                          ),
                        ),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    if (dialogError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          dialogError!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          var rawPhone = phoneController.text.trim();

                          if (newName.isEmpty) {
                            setDialogState(() {
                              dialogError = 'Nama pengguna tidak boleh kosong.';
                            });
                            return;
                          }

                          // Bersihkan nomor telepon
                          rawPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
                          if (rawPhone.startsWith('0')) {
                            rawPhone = rawPhone.substring(1);
                          } else if (rawPhone.startsWith('62')) {
                            rawPhone = rawPhone.substring(2);
                          }

                          final formattedPhone = rawPhone.isNotEmpty ? '+62$rawPhone' : '';

                          setDialogState(() {
                            isSaving = true;
                            dialogError = null;
                          });

                          try {
                            if (SupabaseConstants.isConfigured && _currentUser != null) {
                              final updatedData = Map<String, dynamic>.from(_currentUser!.userMetadata ?? {});
                              updatedData['full_name'] = newName;
                              if (formattedPhone.isNotEmpty) {
                                updatedData['phone'] = formattedPhone;
                              }
                              await Supabase.instance.client.auth.updateUser(
                                UserAttributes(data: updatedData),
                              );
                            }

                            if (mounted) {
                              Navigator.pop(dialogCtx);
                              _loadUserData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Profil berhasil diperbarui!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              dialogError = 'Gagal menyimpan: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
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
      if (SupabaseConstants.isConfigured) {
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
      }
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

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  // Avatar Circle dengan inisial
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
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
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildProfileTile(
                    icon: Icons.email_rounded,
                    label: 'Email Terdaftar',
                    value: email,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildProfileTile(
                    icon: Icons.phone_rounded,
                    label: 'Nomor Telepon',
                    value: phone,
                    showEditHint: true,
                    onTap: _editProfileDialog,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildProfileTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Tanggal Mendaftar',
                    value: regDate,
                  ),
                ],
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

            // Tombol Edit Profil
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _editProfileDialog,
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text(
                  'Ubah Profil & Nomor Telepon',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue, width: 1.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 12),

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
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: value == '-' ? AppColors.textGrey : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            if (showEditHint)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textGrey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

