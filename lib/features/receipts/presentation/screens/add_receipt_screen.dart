import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/category.dart';
import '../../domain/receipt.dart';
import '../controllers/add_receipt_notifier.dart';
import '../widgets/location_search_sheet.dart';

/// Screen untuk menambahkan atau mengubah nota. Menggunakan ConsumerStatefulWidget
/// untuk mengelola controller form lokal dan mengakses state Riverpod.
class AddReceiptScreen extends ConsumerStatefulWidget {
  final Receipt? receiptToEdit;
  
  const AddReceiptScreen({super.key, this.receiptToEdit});

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen> {
  // Controller untuk membaca inputan teks dari pengguna.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _warrantyMonthsController = TextEditingController();
  final TextEditingController _warrantyDaysController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();
  
  // Format durasi garansi: 0 = Bulan Saja, 1 = Hari Saja, 2 = Bulan + Hari
  int _warrantyTypeIndex = 0;
  
  // State lokal UI
  Category? _selectedCategory;
  DateTime? _purchaseDate;
  String? _imagePath;
  String? _warrantyCardPath;

  // State Advanced: Kamera (image_picker)
  bool _isProcessingImage = false;
  bool _isProcessingWarrantyCard = false;

  // State Advanced: Lokasi Toko
  String? _locationError;

  @override
  void initState() {
    super.initState();
    if (widget.receiptToEdit != null) {
      final receipt = widget.receiptToEdit!;
      _nameController.text = receipt.productName;
      // Jika storeName tersimpan dalam format 'Nama Toko (Alamat Lengkap)', pisahkan agar form terisi dengan rapi
      final match = RegExp(r'^(.*?)\s*\((.+)\)$').firstMatch(receipt.storeName);
      if (match != null) {
        _storeController.text = match.group(1)?.trim() ?? receipt.storeName;
        _addressController.text = match.group(2)?.trim() ?? '';
      } else {
        _storeController.text = receipt.storeName;
      }
      
      final m = receipt.warrantyMonths;
      final d = receipt.warrantyDays;
      if (m > 0 && d > 0) {
        _warrantyTypeIndex = 2; // Bulan + Hari
        _warrantyMonthsController.text = m.toString();
        _warrantyDaysController.text = d.toString();
      } else if (d > 0 && m == 0) {
        _warrantyTypeIndex = 1; // Hari Saja
        _warrantyDaysController.text = d.toString();
      } else {
        _warrantyTypeIndex = 0; // Bulan Saja
        _warrantyMonthsController.text = m > 0 ? m.toString() : '';
      }
      
      _selectedCategory = receipt.category;
      _purchaseDate = receipt.purchaseDate;
      _imagePath = receipt.imagePath;
      _warrantyCardPath = receipt.warrantyCardPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeController.dispose();
    _addressController.dispose();
    _warrantyMonthsController.dispose();
    _warrantyDaysController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  DateTime? _calculateExpirationPreview() {
    final base = _purchaseDate ?? DateTime.now();
    int m = 0;
    int d = 0;
    if (_warrantyTypeIndex == 0) {
      m = int.tryParse(_warrantyMonthsController.text.trim()) ?? 0;
    } else if (_warrantyTypeIndex == 1) {
      d = int.tryParse(_warrantyDaysController.text.trim()) ?? 0;
    } else {
      m = int.tryParse(_warrantyMonthsController.text.trim()) ?? 0;
      d = int.tryParse(_warrantyDaysController.text.trim()) ?? 0;
    }
    if (m == 0 && d == 0) return null;
    return DateTime(base.year, base.month + m, base.day).add(Duration(days: d));
  }

  String _getWarrantyDurationSummary() {
    int m = 0;
    int d = 0;
    if (_warrantyTypeIndex == 0) {
      m = int.tryParse(_warrantyMonthsController.text.trim()) ?? 0;
    } else if (_warrantyTypeIndex == 1) {
      d = int.tryParse(_warrantyDaysController.text.trim()) ?? 0;
    } else {
      m = int.tryParse(_warrantyMonthsController.text.trim()) ?? 0;
      d = int.tryParse(_warrantyDaysController.text.trim()) ?? 0;
    }
    if (m > 0 && d > 0) return '$m Bulan $d Hari';
    if (m > 0) return '$m Bulan';
    if (d > 0) return '$d Hari';
    return '-';
  }

  /// Fitur Kamera (image_picker): Memilih gambar dari Kamera atau Galeri.
  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isProcessingImage = true;
    });

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
          _isProcessingImage = false;
        });
        ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(source == ImageSource.camera
                      ? 'Foto nota berhasil diambil dari kamera!'
                      : 'Foto nota berhasil dipilih dari galeri!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isProcessingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Pengambilan foto nota dibatalkan.'),
              ],
            ),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal memproses gambar: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// Fitur Multi-Lampiran: Memilih gambar kartu garansi fisik dari Kamera atau Galeri.
  Future<void> _pickWarrantyCardImage(ImageSource source) async {
    setState(() {
      _isProcessingWarrantyCard = true;
    });

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        setState(() {
          _warrantyCardPath = pickedFile.path;
          _isProcessingWarrantyCard = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(source == ImageSource.camera
                      ? 'Foto kartu garansi berhasil diambil dari kamera!'
                      : 'Foto kartu garansi berhasil dipilih dari galeri!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isProcessingWarrantyCard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingWarrantyCard = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal memproses gambar: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _removeWarrantyCard() {
    setState(() {
      _warrantyCardPath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Foto kartu garansi dihapus.'),
          ],
        ),
        backgroundColor: Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Fitur Lokasi: Membuka dialog/sheet pencarian lokasi toko atau mendeteksi alamat via GPS
  Future<void> _openLocationSearch() async {
    // Prioritaskan alamat toko jika sudah terisi, atau nama toko sebagai kata kunci awal
    String? queryToPass;
    if (_addressController.text.trim().isNotEmpty) {
      queryToPass = _addressController.text.trim();
    } else if (_storeController.text.trim().isNotEmpty) {
      queryToPass = _storeController.text.trim();
    }

    final selectedAddress = await LocationSearchSheet.show(
      context,
      initialQuery: queryToPass,
    );

    if (!mounted) return;

    // Skenario: Alamat tidak ditemukan di OpenStreetMap dan user memilih opsi Isi Manual
    if (selectedAddress != null && selectedAddress.startsWith('MANUAL_INPUT:')) {
      final manualText = selectedAddress.replaceFirst('MANUAL_INPUT:', '').trim();
      setState(() {
        if (manualText.isNotEmpty) {
          _addressController.text = manualText;
        }
        _locationError = null;
      });

      // Tampilkan Pop-up Peringatan Edukatif
      await showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color ?? AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_off_rounded, color: Colors.amber.shade900, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Alamat Tidak Ada di Peta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manualText.isNotEmpty
                    ? 'Lokasi "$manualText" belum terdaftar di OpenStreetMap.'
                    : 'Alamat toko yang Anda cari belum terdaftar di OpenStreetMap.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: AppColors.primaryBlue, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Silakan lengkapi atau ketik alamat toko secara manual pada kolom "Alamat Toko" di bawah.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Mengerti, Isi Manual'),
            ),
          ],
        ),
      );

      // Fokuskan kursor ke TextField Alamat Toko agar pengguna bisa langsung mengetik
      _addressFocusNode.requestFocus();
      return;
    }

    if (selectedAddress != null && selectedAddress.trim().isNotEmpty && mounted) {
      setState(() {
        _addressController.text = selectedAddress.trim();
        _locationError = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Alamat toko berhasil dipilih: $selectedAddress'),
              ),
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
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
      ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
    }
  }

  Widget _buildWarrantyTypeChip({required int index, required String label}) {
    final isSelected = _warrantyTypeIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _warrantyTypeIndex = index;
          });
          ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  /// Fungsi ini dipanggil ketika user menekan tombol "Simpan Nota".
  Future<void> _onSubmit() async {
    final notifier = ref.read(addReceiptNotifierProvider.notifier);
    
    final String storeText = _addressController.text.trim().isNotEmpty
        ? '${_storeController.text.trim()} (${_addressController.text.trim()})'
        : _storeController.text.trim();

    int months = 0;
    int days = 0;
    if (_warrantyTypeIndex == 0) {
      months = int.tryParse(_warrantyMonthsController.text.trim()) ?? 0;
    } else if (_warrantyTypeIndex == 1) {
      days = int.tryParse(_warrantyDaysController.text.trim()) ?? 0;
    } else {
      months = int.tryParse(_warrantyMonthsController.text.trim()) ?? 0;
      days = int.tryParse(_warrantyDaysController.text.trim()) ?? 0;
    }

    final savedReceipt = await notifier.submitReceipt(
      editId: widget.receiptToEdit?.id,
      productName: _nameController.text, 
      selectedCategory: _selectedCategory,
      storeName: storeText,
      purchaseDate: _purchaseDate,
      warrantyMonths: months,
      warrantyDays: days,
      imagePath: _imagePath,
      warrantyCardPath: _warrantyCardPath,
    );

    if (mounted) {
      if (savedReceipt != null) {
        await NotificationService().showReceiptSavedNotification(
          productName: _nameController.text.trim(),
          storeName: _storeController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.receiptToEdit == null
                        ? 'Nota berhasil disimpan ke Server & Notifikasi terkirim!'
                        : 'Nota berhasil diubah!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final error = ref.read(addReceiptNotifierProvider).validationError;
        if (error != null && error.startsWith('Gagal')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addReceiptNotifierProvider);

    // Keyboard-Safe UI: Ambil bottom viewInsets agar input box tidak tertutup keyboard
    final keyboardBottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.receiptToEdit == null ? 'Tambah Nota' : 'Ubah Nota'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: state.categoriesState.when(
            // KONDISI 1: Initial Loading
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat daftar kategori...'),
                ],
              ),
            ),
            
            // KONDISI 4: Error State
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    error.toString(), 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label: 'Tombol coba lagi',
                    hint: 'Ketuk untuk memuat ulang daftar kategori',
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(addReceiptNotifierProvider.notifier).fetchCategories();
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ),
                ],
              ),
            ),
            
            // KONDISI 2 & 3: Data sukses dimuat, ATAU Empty State
            data: (categories) {
              // KONDISI 3: Empty state
              if (categories.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Daftar kategori nota kosong. Harap tambahkan kategori pada sistem terlebih dahulu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }
              
              // KONDISI 2: Data sukses dimuat (Formulir tampil sempurna)
              // Keyboard-Safe UI: Bungkus seluruh form input dalam SingleChildScrollView dengan padding keyboard
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: keyboardBottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ===================================================
                          // Form Upload / Kamera Foto Nota (image_picker)
                          // ===================================================
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: state.validationError != null && state.validationError!.contains('Foto') 
                                    ? Colors.red 
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: _isProcessingImage
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 12),
                                        Text('Memproses gambar nota...'),
                                      ],
                                    ),
                                  )
                                : _imagePath != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: _imagePath!.startsWith('http')
                                                ? Image.network(
                                                    _imagePath!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (ctx, error, stackTrace) => const Center(
                                                      child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                                    ),
                                                  )
                                                : Image.file(
                                                    File(_imagePath!),
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Row(
                                              children: [
                                                Semantics(
                                                  button: true,
                                                  label: 'Foto ulang nota dengan kamera',
                                                  hint: 'Ketuk untuk mengambil foto nota baru dari kamera',
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => _pickImage(ImageSource.camera),
                                                    icon: const Icon(Icons.camera_alt, size: 16),
                                                    label: const Text('Foto Ulang'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Semantics(
                                                  button: true,
                                                  label: 'Pilih foto ulang dari galeri',
                                                  hint: 'Ketuk untuk memilih foto nota lain dari galeri',
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => _pickImage(ImageSource.gallery),
                                                    icon: const Icon(Icons.photo_library, size: 16),
                                                    label: const Text('Galeri'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.primaryBlue.withValues(alpha: 0.7)),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Lampirkan Foto Nota',
                                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Semantics(
                                                button: true,
                                                label: 'Buka kamera',
                                                hint: 'Ketuk untuk mengambil foto nota langsung dengan kamera HP',
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _pickImage(ImageSource.camera),
                                                  icon: const Icon(Icons.camera_alt, size: 18),
                                                  label: const Text('Buka Kamera'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.primaryBlue,
                                                    foregroundColor: Colors.white,
                                                    elevation: 2,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Semantics(
                                                button: true,
                                                label: 'Pilih dari galeri',
                                                hint: 'Ketuk untuk memilih gambar foto nota yang sudah ada di galeri',
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _pickImage(ImageSource.gallery),
                                                  icon: const Icon(Icons.photo_library, size: 18),
                                                  label: const Text('Dari Galeri'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                          ),
                          if (state.validationError != null && state.validationError!.contains('Foto'))
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                              child: Text(
                                state.validationError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // ===================================================
                          // Form Upload Foto Kartu Garansi Fisik (Opsional)
                          // ===================================================
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.primaryBlue),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Foto Kartu Garansi Fisik',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Opsional',
                                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sertakan foto fisik kartu garansi, barcode toko, atau nomor seri IMEI sebagai bukti cadangan.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 10),
                                if (_isProcessingWarrantyCard)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (_warrantyCardPath != null)
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          height: 140,
                                          width: double.infinity,
                                          child: _warrantyCardPath!.startsWith('http')
                                              ? Image.network(
                                                  _warrantyCardPath!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (ctx, err, stack) => const Center(
                                                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                  ),
                                                )
                                              : Image.file(
                                                  File(_warrantyCardPath!),
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.black.withValues(alpha: 0.65),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                            onPressed: _removeWarrantyCard,
                                            tooltip: 'Hapus foto garansi',
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 6,
                                        right: 6,
                                        child: Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => _pickWarrantyCardImage(ImageSource.camera),
                                              icon: const Icon(Icons.camera_alt, size: 14),
                                              label: const Text('Kamera', style: TextStyle(fontSize: 11)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black.withValues(alpha: 0.7),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            ElevatedButton.icon(
                                              onPressed: () => _pickWarrantyCardImage(ImageSource.gallery),
                                              icon: const Icon(Icons.photo_library, size: 14),
                                              label: const Text('Galeri', style: TextStyle(fontSize: 11)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black.withValues(alpha: 0.7),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _pickWarrantyCardImage(ImageSource.camera),
                                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                          label: const Text('Kamera', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _pickWarrantyCardImage(ImageSource.gallery),
                                          icon: const Icon(Icons.photo_library_outlined, size: 16),
                                          label: const Text('Galeri', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Form Input Nama Barang
                          Semantics(
                            textField: true,
                            label: 'Kolom input nama barang',
                            hint: 'Ketik nama barang belanjaan Anda',
                            child: TextField(
                              controller: _nameController,
                              autocorrect: false,
                              enableSuggestions: false,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Nama Barang',
                                border: const OutlineInputBorder(),
                                errorText: state.validationError != null && state.validationError!.contains('Nama barang')
                                    ? state.validationError
                                    : null,
                              ),
                              onChanged: (_) => ref.read(addReceiptNotifierProvider.notifier).clearValidationError(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Form Input Nama Toko
                          Semantics(
                            textField: true,
                            label: 'Kolom input nama toko',
                            hint: 'Ketik nama toko tempat pembelian barang',
                            child: TextField(
                              controller: _storeController,
                              autocorrect: false,
                              enableSuggestions: false,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Nama Toko',
                                border: const OutlineInputBorder(),
                                errorText: state.validationError != null && state.validationError!.contains('Nama toko')
                                    ? state.validationError
                                    : null,
                              ),
                              onChanged: (_) => ref.read(addReceiptNotifierProvider.notifier).clearValidationError(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ===================================================
                          // Form Lokasi Toko & Tombol Cari Lokasi Toko
                          // ===================================================
                          Semantics(
                            textField: true,
                            label: 'Kolom input alamat toko',
                            hint: 'Ketik alamat toko atau gunakan tombol cari lokasi toko',
                            child: TextField(
                              controller: _addressController,
                              focusNode: _addressFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Alamat Toko',
                                hintText: 'Contoh: Jl. Jenderal Sudirman No. 12, Jakarta',
                                border: const OutlineInputBorder(),
                                suffixIcon: _addressController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _addressController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tombol 'Cari Lokasi Toko'
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Semantics(
                              button: true,
                              label: 'Tombol cari lokasi toko',
                              hint: 'Ketuk untuk mencari alamat lengkap toko atau menggunakan GPS',
                              child: OutlinedButton.icon(
                                onPressed: _openLocationSearch,
                                icon: const Icon(Icons.search_rounded, size: 18),
                                label: const Text('Cari Lokasi Toko'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  side: const BorderSide(color: AppColors.primaryBlue),
                                ),
                              ),
                            ),
                          ),
                          if (_locationError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                              child: Text(
                                _locationError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 16),
                          
                          // Form Dropdown Kategori
                          Semantics(
                            button: true,
                            label: 'Pilihan kategori nota',
                            hint: 'Pilih salah satu kategori barang yang cocok',
                            child: DropdownButtonFormField<Category>(
                              initialValue: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Kategori Nota',
                                border: const OutlineInputBorder(),
                                errorText: state.validationError != null && state.validationError!.contains('Kategori')
                                    ? state.validationError
                                    : null,
                              ),
                              hint: const Text('Pilih Kategori'),
                              items: categories.map((Category cat) {
                                return DropdownMenuItem<Category>(
                                  value: cat,
                                  child: Text(cat.label),
                                );
                              }).toList(),
                              onChanged: (Category? newValue) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                                ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Form Tanggal Beli
                          Semantics(
                            button: true,
                            label: 'Pilihan tanggal beli',
                            hint: 'Ketuk untuk membuka pemilih tanggal pembelian',
                            child: InkWell(
                              onTap: _pickDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Tanggal Beli',
                                  border: const OutlineInputBorder(),
                                  errorText: state.validationError != null && state.validationError!.contains('Tanggal beli')
                                      ? state.validationError
                                      : null,
                                ),
                                child: Text(
                                  _purchaseDate == null
                                      ? 'Pilih Tanggal'
                                      : DateFormat('dd MMMM yyyy', 'id_ID').format(_purchaseDate!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Pilihan Format Durasi Garansi (Bulan / Hari / Bulan + Hari)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.primaryBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pilihan Waktu Garansi',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildWarrantyTypeChip(index: 0, label: 'Bulan'),
                                  const SizedBox(width: 8),
                                  _buildWarrantyTypeChip(index: 1, label: 'Hari'),
                                  const SizedBox(width: 8),
                                  _buildWarrantyTypeChip(index: 2, label: 'Bulan + Hari'),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Form Input Durasi Sesuai Pilihan
                              if (_warrantyTypeIndex == 0)
                                Semantics(
                                  textField: true,
                                  label: 'Kolom input durasi garansi dalam bulan',
                                  hint: 'Ketik angka durasi garansi dalam hitungan bulan',
                                  child: TextField(
                                    controller: _warrantyMonthsController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Durasi Garansi',
                                      suffixText: 'Bulan',
                                      border: const OutlineInputBorder(),
                                      errorText: state.validationError != null && state.validationError!.contains('Durasi garansi')
                                          ? state.validationError
                                          : null,
                                    ),
                                    onChanged: (_) {
                                      setState(() {});
                                      ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
                                    },
                                  ),
                                )
                              else if (_warrantyTypeIndex == 1)
                                Semantics(
                                  textField: true,
                                  label: 'Kolom input durasi garansi dalam hari',
                                  hint: 'Ketik angka durasi garansi dalam hitungan hari',
                                  child: TextField(
                                    controller: _warrantyDaysController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Durasi Garansi',
                                      suffixText: 'Hari',
                                      border: const OutlineInputBorder(),
                                      errorText: state.validationError != null && state.validationError!.contains('Durasi garansi')
                                          ? state.validationError
                                          : null,
                                    ),
                                    onChanged: (_) {
                                      setState(() {});
                                      ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
                                    },
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: Semantics(
                                        textField: true,
                                        label: 'Kolom durasi bulan garansi',
                                        child: TextField(
                                          controller: _warrantyMonthsController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Bulan',
                                            suffixText: 'Bln',
                                            border: const OutlineInputBorder(),
                                            errorText: state.validationError != null && state.validationError!.contains('Durasi garansi')
                                                ? state.validationError
                                                : null,
                                          ),
                                          onChanged: (_) {
                                            setState(() {});
                                            ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Semantics(
                                        textField: true,
                                        label: 'Kolom durasi hari garansi',
                                        child: TextField(
                                          controller: _warrantyDaysController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Hari',
                                            suffixText: 'Hari',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (_) {
                                            setState(() {});
                                            ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              // Live Preview Kartu Masa Berlaku Garansi
                              if (_calculateExpirationPreview() != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, color: AppColors.primaryBlue, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Garansi: ${_getWarrantyDurationSummary()} (Berakhir ${DateFormat('dd MMMM yyyy', 'id_ID').format(_calculateExpirationPreview()!)})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ===================================================
                  // KONDISI 6: Loading submit
                  // ===================================================
                  Semantics(
                    button: true,
                    label: widget.receiptToEdit == null ? 'Tombol simpan nota' : 'Tombol simpan perubahan nota',
                    hint: 'Ketuk untuk menyimpan data nota ke server cloud',
                    child: ElevatedButton(
                      onPressed: state.isSubmitting ? null : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: state.isSubmitting 
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              widget.receiptToEdit == null ? 'Simpan Nota' : 'Simpan Perubahan',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
