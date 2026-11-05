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
  final TextEditingController _warrantyController = TextEditingController();
  
  // State lokal UI
  Category? _selectedCategory;
  DateTime? _purchaseDate;
  String? _imagePath;

  // State Advanced: Kamera (image_picker)
  bool _isProcessingImage = false;

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
      _warrantyController.text = receipt.warrantyMonths.toString();
      _selectedCategory = receipt.category;
      _purchaseDate = receipt.purchaseDate;
      _imagePath = receipt.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeController.dispose();
    _addressController.dispose();
    _warrantyController.dispose();
    super.dispose();
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

  /// Fungsi ini dipanggil ketika user menekan tombol "Simpan Nota".
  Future<void> _onSubmit() async {
    final notifier = ref.read(addReceiptNotifierProvider.notifier);
    
    final String storeText = _addressController.text.trim().isNotEmpty
        ? '${_storeController.text.trim()} (${_addressController.text.trim()})'
        : _storeController.text.trim();

    final success = await notifier.submitReceipt(
      editId: widget.receiptToEdit?.id,
      productName: _nameController.text, 
      selectedCategory: _selectedCategory,
      storeName: storeText,
      purchaseDate: _purchaseDate,
      warrantyMonths: _warrantyController.text,
      imagePath: _imagePath,
    );

    if (mounted) {
      if (success) {
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

                          // Form Durasi Garansi
                          Semantics(
                            textField: true,
                            label: 'Kolom input durasi garansi dalam bulan',
                            hint: 'Ketik angka lama waktu garansi barang',
                            child: TextField(
                              controller: _warrantyController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Durasi Garansi (Bulan)',
                                border: const OutlineInputBorder(),
                                errorText: state.validationError != null && state.validationError!.contains('Durasi garansi')
                                    ? state.validationError
                                    : null,
                              ),
                              onChanged: (_) => ref.read(addReceiptNotifierProvider.notifier).clearValidationError(),
                            ),
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
