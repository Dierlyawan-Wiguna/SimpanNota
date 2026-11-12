import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/profile_validator.dart';

/// Data model transfer untuk data inputan formulir profil
class ProfileFormData {
  final String name;
  final String phone;

  const ProfileFormData({
    required this.name,
    required this.phone,
  });
}

/// Widget formulir pengeditan data profil pengguna.
/// Bertanggung jawab murni atas: input text, form controller, status loading, dan error UI.
/// Menerapkan Single Responsibility Principle (SRP) & Separation of Concerns.
class ProfileForm extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final bool isLoading;
  final String? externalError;
  final Future<void> Function(ProfileFormData data) onSubmit;
  final VoidCallback? onCancel;

  const ProfileForm({
    super.key,
    required this.initialName,
    required this.initialPhone,
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
  String? _localError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(
      text: ProfileValidator.cleanPhoneForInput(widget.initialPhone),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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

    setState(() => _localError = null);
    final formattedPhone = ProfileValidator.formatPhone(_phoneController.text);
    widget.onSubmit(ProfileFormData(name: name, phone: formattedPhone));
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
        TextField(
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
        const SizedBox(height: 16),
        const Text(
          'Nomor Telepon (WhatsApp)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        TextField(
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

