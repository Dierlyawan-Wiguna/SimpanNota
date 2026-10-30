import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/category.dart';
import '../../domain/receipt.dart';
import '../controllers/add_receipt_notifier.dart';

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

  // State Advanced: Lokasi (geolocator)
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    if (widget.receiptToEdit != null) {
      final receipt = widget.receiptToEdit!;
      _nameController.text = receipt.productName;
      _storeController.text = receipt.storeName;
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
  /// Menampilkan status loading saat memproses, dan menangani pembatalan (cancel).
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
            content: Text(source == ImageSource.camera
                ? 'Foto nota berhasil diambil dari kamera!'
                : 'Foto nota berhasil dipilih dari galeri!'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Pengguna membatalkan proses pemotretan / pemilihan foto
        setState(() {
          _isProcessingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengambilan foto nota dibatalkan.'),
            duration: Duration(seconds: 2),
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
            content: Text('Gagal memproses gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Fitur Lokasi (geolocator): Mendapatkan koordinat lokasi pengguna secara otomatis.
  /// Menangani alur perizinan, status GPS aktif/mati, loading, dan pesan error jika ditolak.
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // 1. Cek apakah layanan GPS pada perangkat aktif
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'GPS tidak aktif. Harap aktifkan GPS pada perangkat Anda.';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS tidak aktif. Harap aktifkan GPS perangkat Anda.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 2. Cek dan minta perizinan akses lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationError = 'Izin lokasi ditolak oleh pengguna.';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin akses lokasi ditolak oleh pengguna.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Izin lokasi ditolak permanen. Silakan aktifkan via Pengaturan HP.';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak permanen. Buka Pengaturan untuk mengaktifkan.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 3. Ambil posisi koordinat saat ini
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      final formattedAddress =
          'Koordinat: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      setState(() {
        _isLoadingLocation = false;
        _addressController.text = formattedAddress;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi berhasil diambil: $formattedAddress'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Gagal mencari koordinat: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan lokasi: $e'),
          backgroundColor: Colors.red,
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
    // Membaca object notifier untuk mengeksekusi logika submitReceipt.
    final notifier = ref.read(addReceiptNotifierProvider.notifier);
    
    // Gabungkan nama toko dengan alamat/koordinat jika diisi
    final String storeText = _addressController.text.trim().isNotEmpty
        ? '${_storeController.text.trim()} (${_addressController.text.trim()})'
        : _storeController.text.trim();

    // Meneruskan data form dari UI ke layer Notifier/Controller untuk divalidasi dan diproses.
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
        // Fitur Notifikasi (flutter_local_notifications):
        // Memicu notifikasi sukses yang muncul di system tray HP setiap kali pengguna selesai/berhasil menyimpan nota baru.
        await NotificationService().showReceiptSavedNotification(
          productName: _nameController.text.trim(),
          storeName: _storeController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.receiptToEdit == null
                ? 'Nota berhasil disimpan ke Server & Notifikasi terkirim!'
                : 'Nota berhasil diubah!'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final error = ref.read(addReceiptNotifierProvider).validationError;
        if (error != null && error.startsWith('Gagal menyimpan')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addReceiptNotifierProvider);

    return Scaffold(
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
                  ElevatedButton(
                    onPressed: () {
                      ref.read(addReceiptNotifierProvider.notifier).fetchCategories();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
            
            // KONDISI 2 & 3: Data sukses dimuat, ATAU Empty State
            data: (categories) {
              // KONDISI 3: Empty state
              if (categories.isEmpty) {
                return const Center(
                  child: Text(
                    'Daftar kategori nota kosong. Harap tambahkan kategori pada sistem terlebih dahulu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              
              // KONDISI 2: Data sukses dimuat (Formulir tampil sempurna)
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
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
                                            child: Image.file(
                                              File(_imagePath!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Row(
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () => _pickImage(ImageSource.camera),
                                                  icon: const Icon(Icons.camera_alt, size: 16),
                                                  label: const Text('Foto Ulang'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.black.withValues(alpha: 0.7),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                ElevatedButton.icon(
                                                  onPressed: () => _pickImage(ImageSource.gallery),
                                                  icon: const Icon(Icons.photo_library, size: 16),
                                                  label: const Text('Galeri'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.black.withValues(alpha: 0.7),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                              ElevatedButton.icon(
                                                onPressed: () => _pickImage(ImageSource.camera),
                                                icon: const Icon(Icons.camera_alt, size: 18),
                                                label: const Text('Buka Kamera'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primaryBlue,
                                                  foregroundColor: Colors.white,
                                                  elevation: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              OutlinedButton.icon(
                                                onPressed: () => _pickImage(ImageSource.gallery),
                                                icon: const Icon(Icons.photo_library, size: 18),
                                                label: const Text('Dari Galeri'),
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
                          TextField(
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
                          const SizedBox(height: 16),
                          
                          // Form Input Nama Toko
                          TextField(
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
                          const SizedBox(height: 16),

                          // ===================================================
                          // Form Lokasi Toko & Tombol Geolocator
                          // ===================================================
                          TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Alamat / Koordinat Toko',
                              hintText: 'Contoh: Jl. Sudirman No. 12 atau Koordinat GPS',
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
                          const SizedBox(height: 8),

                          // Tombol 'Ambil Lokasi Saat Ini'
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                              icon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location, size: 18),
                              label: Text(_isLoadingLocation
                                  ? 'Mencari Koordinat...'
                                  : 'Ambil Lokasi Saat Ini'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(color: AppColors.primaryBlue),
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
                          DropdownButtonFormField<Category>(
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
                          const SizedBox(height: 16),

                          // Form Tanggal Beli
                          InkWell(
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
                          const SizedBox(height: 16),

                          // Form Durasi Garansi
                          TextField(
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
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ===================================================
                  // KONDISI 6: Loading submit
                  // ===================================================
                  ElevatedButton(
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

                  // PANEL SIMULASI PENGUJIAN
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Panel Simulasi Pengujian:', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.error, size: 16),
                        label: const Text('Test Error'),
                        onPressed: () => ref.read(addReceiptNotifierProvider.notifier).fetchCategories(simulateError: true),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep, size: 16),
                        label: const Text('Test Empty'),
                        onPressed: () => ref.read(addReceiptNotifierProvider.notifier).fetchCategories(simulateEmpty: true),
                      ),
                    ],
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
