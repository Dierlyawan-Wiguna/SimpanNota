import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/profile_validator.dart';

/// Dialog formulir pengubahan kata sandi pengguna.
/// Menerapkan SRP dengan menangani murni UI input kata sandi baru dan konfirmasi.
class PasswordFormDialog extends StatefulWidget {
  final Future<void> Function(String newPassword) onSubmit;

  const PasswordFormDialog({
    super.key,
    required this.onSubmit,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<void> Function(String newPassword) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PasswordFormDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<PasswordFormDialog> createState() => _PasswordFormDialogState();
}

class _PasswordFormDialogState extends State<PasswordFormDialog> {
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isObscure = true;
  bool _isSaving = false;
  String? _dialogError;

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final validationError = ProfileValidator.validatePasswordChange(
      newPassword: _passController.text,
      confirmPassword: _confirmPassController.text,
    );
    if (validationError != null) {
      setState(() => _dialogError = validationError);
      return;
    }

    setState(() {
      _isSaving = true;
      _dialogError = null;
    });

    try {
      await widget.onSubmit(_passController.text);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _dialogError = 'Gagal mengubah kata sandi: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFE2E8F0) : AppColors.textDark;
    final fieldFillColor = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final fieldBorderColor = isDark ? const Color(0xFF334155) : AppColors.cardBorder;
    final textStyle = TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 14);

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
              Icons.lock_reset_rounded,
              color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Ubah Kata Sandi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan kata sandi baru untuk akun Anda (minimal 6 karakter).',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kata Sandi Baru',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passController,
              obscureText: _isObscure,
              enabled: !_isSaving,
              style: textStyle,
              decoration: InputDecoration(
                hintText: 'Minimal 6 karakter',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryBlue,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
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
            const SizedBox(height: 14),
            Text(
              'Konfirmasi Kata Sandi Baru',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmPassController,
              obscureText: _isObscure,
              enabled: !_isSaving,
              style: textStyle,
              decoration: InputDecoration(
                hintText: 'Ulangi kata sandi baru',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: Icon(
                  Icons.lock_outline,
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
            if (_dialogError != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _dialogError!,
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

