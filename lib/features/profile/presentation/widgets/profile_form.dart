import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/profile_validator.dart';

/// Data model transfer untuk data inputan formulir profil
class ProfileFormData {
  final String name;
  final String phone;
  final String? telegramChatId;
  final String? telegramBotToken;

  const ProfileFormData({
    required this.name,
    required this.phone,
    this.telegramChatId,
    this.telegramBotToken,
  });
}

/// Widget formulir pengeditan data profil pengguna.
/// Bertanggung jawab murni atas: input text, form controller, status loading, dan error UI.
/// Menerapkan Single Responsibility Principle (SRP) & Separation of Concerns.
class ProfileForm extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String? initialTelegramChatId;
  final String? initialTelegramBotToken;
  final bool isLoading;
  final String? externalError;
  final Future<void> Function(ProfileFormData data) onSubmit;
  final VoidCallback? onCancel;

  const ProfileForm({
    super.key,
    required this.initialName,
    required this.initialPhone,
    this.initialTelegramChatId,
    this.initialTelegramBotToken,
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
    String? initialTelegramBotToken,
    required Future<void> Function(ProfileFormData data) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isSaving = false;
        String? dialogError;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ubah Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: ProfileForm(
                  initialName: initialName,
                  initialPhone: initialPhone,
                  initialTelegramChatId: initialTelegramChatId,
                  initialTelegramBotToken: initialTelegramBotToken,
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
  late final TextEditingController _botTokenController;
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
    _botTokenController = TextEditingController(
      text: widget.initialTelegramBotToken ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _botTokenController.dispose();
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
    final botToken = _botTokenController.text.trim().isEmpty ? null : _botTokenController.text.trim();
    widget.onSubmit(ProfileFormData(
      name: name,
      phone: formattedPhone,
      telegramChatId: tgId,
      telegramBotToken: botToken,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeError = widget.externalError ?? _localError;

    final labelColor = isDark ? const Color(0xFFE2E8F0) : AppColors.textDark;
    final fieldFillColor = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final fieldBorderColor = isDark ? const Color(0xFF334155) : AppColors.cardBorder;
    final textStyle = TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 14);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama Pengguna',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Kolom input Nama Pengguna',
          hint: 'Masukkan nama pengguna Anda',
          child: TextField(
            controller: _nameController,
            enabled: !widget.isLoading,
            style: textStyle,
            decoration: InputDecoration(
              hintText: 'Nama lengkap Anda',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: Icon(
                Icons.person_outline,
                color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryBlue,
              ),
              filled: true,
              fillColor: fieldFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryBlue,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Nomor Telepon',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Kolom input Nomor Telepon',
          hint: 'Masukkan nomor telepon diawali angka setelah 0 atau 62',
          child: TextField(
            controller: _phoneController,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.phone,
            style: textStyle,
            decoration: InputDecoration(
              hintText: '81234567890',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+62',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryBlue,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 20,
                      child: VerticalDivider(color: fieldBorderColor, width: 1),
                    ),
                  ],
                ),
              ),
              filled: true,
              fillColor: fieldFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryBlue,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Telegram Chat ID (Opsional)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Kolom input Telegram Chat ID',
          hint: 'Masukkan Chat ID angka untuk menerima pengingat garansi via Telegram bot',
          child: TextFormField(
            controller: _telegramController,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.number,
            style: textStyle,
            decoration: InputDecoration(
              hintText: 'Contoh: 123456789',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.send_rounded, color: Color(0xFF0088CC)),
              filled: true,
              fillColor: fieldFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFF0088CC), width: 1.5),
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
            color: isDark ? const Color(0xFF0F2B48) : const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF1E4976) : const Color(0xFFBAE6FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
                          height: 1.3,
                        ),
                        children: const [
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new,
                            size: 13,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Buka @userinfobot',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Buka bot BotFather di Telegram',
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse('https://t.me/BotFather');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 13,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Buka @BotFather',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
                      child: Text(
                        'Download Telegram',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
        const SizedBox(height: 16),

        // Field Telegram Bot Token (Opsional untuk pengiriman otomatis)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Telegram Bot Token (Kirim Otomatis)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Opsional',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Kolom input Telegram Bot Token',
          hint: 'Masukkan token bot dari BotFather agar pesan pengingat terkirim 100% otomatis',
          child: TextFormField(
            controller: _botTokenController,
            enabled: !widget.isLoading,
            style: textStyle,
            decoration: InputDecoration(
              hintText: 'Contoh: 123456789:ABCdefGhIJKlmNo...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: Icon(
                Icons.smart_toy_outlined,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0088CC),
              ),
              filled: true,
              fillColor: fieldFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFF0088CC), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dapatkan token dari @BotFather di Telegram lalu klik Mulai di bot Anda untuk pengiriman 100% otomatis.',
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
            height: 1.3,
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
