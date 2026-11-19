import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/profile_validator.dart';

/// Data model transfer untuk data inputan formulir profil
class ProfileFormData {
  final String name;
  final String phone;
  final String? telegramChatId;

  const ProfileFormData({
    required this.name,
    required this.phone,
    this.telegramChatId,
  });
}

/// Widget formulir pengeditan data profil pengguna.
/// Bertanggung jawab murni atas: input text, form controller, status loading, dan error UI.
/// Menerapkan Single Responsibility Principle (SRP) & Separation of Concerns.
class ProfileForm extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String? initialTelegramChatId;
  final bool isLoading;
  final String? externalError;
  final Future<void> Function(ProfileFormData data) onSubmit;
  final VoidCallback? onCancel;

  const ProfileForm({
    super.key,
    required this.initialName,
    required this.initialPhone,
    this.initialTelegramChatId,
    this.isLoading = false,
    this.externalError,
    required this.onSubmit,
    this.onCancel,
  });

  /// Helper statis untuk menampilkan ProfileForm di dalam AlertDialog modal
  static Future<void> showAsDialog({
    required BuildContext context,
    required String initialName,
    required String initialPhone,
    String? initialTelegramChatId,
    required Future<void> Function(ProfileFormData data) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isSaving = false;
        String? dialogError;

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
                child: ProfileForm(
                  initialName: initialName,
                  initialPhone: initialPhone,
                  initialTelegramChatId: initialTelegramChatId,
                  isLoading: isSaving,
                  externalError: dialogError,
                  onCancel: () => Navigator.pop(dialogCtx),
                  onSubmit: (data) async {
                    setDialogState(() {
                      isSaving = true;
                      dialogError = null;
                    });
                    try {
                      await onSubmit(data);
                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                    } catch (e) {
                      setDialogState(() {
                        isSaving = false;
                        dialogError = 'Gagal menyimpan: $e';
                      });
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _telegramController;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(
      text: ProfileValidator.cleanPhoneForInput(widget.initialPhone),
    );
    _telegramController = TextEditingController(
      text: widget.initialTelegramChatId ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final name = _nameController.text.trim();
    final nameError = ProfileValidator.validateDisplayName(name);
    if (nameError != null) {
      setState(() => _localError = nameError);
      return;
    }

    final phoneError = ProfileValidator.validatePhoneNumber(
      _phoneController.text,
      isOptional: true,
    );
    if (phoneError != null) {
      setState(() => _localError = phoneError);
      return;
    }

    final tgError = ProfileValidator.validateTelegramChatId(_telegramController.text);
    if (tgError != null) {
      setState(() => _localError = tgError);
      return;
    }

    setState(() => _localError = null);
    final formattedPhone = ProfileValidator.formatPhone(_phoneController.text);
    final tgId = _telegramController.text.trim().isEmpty ? null : _telegramController.text.trim();
    widget.onSubmit(ProfileFormData(
      name: name,
      phone: formattedPhone,
      telegramChatId: tgId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final activeError = widget.externalError ?? _localError;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama Pengguna',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Kolom input Nama Pengguna',
          hint: 'Masukkan nama pengguna Anda',
          child: TextField(
            controller: _nameController,
            enabled: !widget.isLoading,
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
        ),
        const SizedBox(height: 16),
        const Text(
          'Nomor Telepon',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Kolom input Nomor Telepon',
          hint: 'Masukkan nomor telepon diawali angka setelah 0 atau 62',
          child: TextField(
            controller: _phoneController,
            enabled: !widget.isLoading,
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
        ),
        const SizedBox(height: 16),
        const Text(
          'Telegram Chat ID (Opsional)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Kolom input Telegram Chat ID',
          hint: 'Masukkan Chat ID angka untuk menerima pengingat garansi via Telegram bot',
          child: TextFormField(
            controller: _telegramController,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Contoh: 123456789',
              prefixIcon: const Icon(Icons.send_rounded, color: Color(0xFF0088CC)),
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
                borderSide: const BorderSide(color: Color(0xFF0088CC), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Helper teks dan tautan interaktif
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 11, color: Color(0xFF0369A1), height: 1.3),
                        children: [
                          TextSpan(text: 'Dapatkan User ID angka Anda dari bot '),
                          TextSpan(
                            text: '@userinfobot',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' di Telegram lalu tekan /start.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Semantics(
                    button: true,
                    label: 'Buka bot userinfobot di Telegram',
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse('https://t.me/userinfobot');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new, size: 13, color: Color(0xFF0284C7)),
                          SizedBox(width: 4),
                          Text(
                            'Buka @userinfobot',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Tautan unduh aplikasi Telegram di Google Play Store',
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse(
                          'https://play.google.com/store/apps/details?id=org.telegram.messenger',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Text(
                        'Belum punya Telegram? Download di sini',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (activeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              activeError,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onCancel != null)
              TextButton(
                onPressed: widget.isLoading ? null : widget.onCancel,
                child: const Text(
                  'Batal',
                  style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ],
    );
  }
}
