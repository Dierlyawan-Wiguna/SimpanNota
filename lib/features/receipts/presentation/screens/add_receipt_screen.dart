import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../domain/category.dart';
import '../controllers/add_receipt_notifier.dart';

import '../../domain/receipt.dart';

/// Screen untuk menambahkan nota baru. Menggunakan ConsumerStatefulWidget
/// karena kita butuh TextEditingController (Stateful) dan juga butuh
/// mengakses/mengamati state dari Riverpod (Consumer).
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
  final TextEditingController _warrantyController = TextEditingController();
  
  // State lokal UI
  Category? _selectedCategory;
  DateTime? _purchaseDate;
  String? _imagePath;

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
    _warrantyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
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
    // Menggunakan ref.read() (bukan ref.watch) karena fungsi ini dipanggil 
    // dalam event callback (onPressed), bukan saat build method.
    final notifier = ref.read(addReceiptNotifierProvider.notifier);
    
    // Meneruskan data form dari UI ke layer Notifier/Controller untuk divalidasi dan diproses.
    final success = await notifier.submitReceipt(
      editId: widget.receiptToEdit?.id,
      productName: _nameController.text, 
      selectedCategory: _selectedCategory,
      storeName: _storeController.text,
      purchaseDate: _purchaseDate,
      warrantyMonths: _warrantyController.text,
      imagePath: _imagePath,
    );

    // Cek mounted sebelum mengeksekusi aksi BuildContext setelah operasi asinkron (await).
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.receiptToEdit == null ? 'Nota berhasil disimpan!' : 'Nota berhasil diubah!')),
      );
      // Di aplikasi penuh, ini akan berupa Navigator.pop() atau goRouter untuk kembali ke Home.
      // Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengamati/Subscribe state terbaru dari Notifier.
    // Setiap kali `state` di dalam AddReceiptNotifier berubah (via copyWith), 
    // block `build()` ini akan dipanggil ulang (re-build) untuk mencerminkan UI yang baru.
    final state = ref.watch(addReceiptNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiptToEdit == null ? 'Tambah Nota' : 'Ubah Nota'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          
          // Menggunakan fitur pattern matching dari `AsyncValue` (Riverpod)
          // Memudahkan kita membagi UI menjadi 3 skenario: Loading, Data Sukses, Error.
          child: state.categoriesState.when(
            
            // =================================================================
            // KONDISI 1: Initial Loading
            // Tampilan saat repository sedang mengambil daftar kategori nota.
            // =================================================================
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
            
            // =================================================================
            // KONDISI 4: Error State
            // Tampilan jika proses pengambilan kategori dari repository gagal.
            // Lengkap dengan tombol "Coba Lagi" untuk mencoba mengulang request (retry).
            // =================================================================
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
                      // Trigger aksi fetch ulang (retry) pada Notifier.
                      ref.read(addReceiptNotifierProvider.notifier).fetchCategories();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
            
            // =================================================================
            // KONDISI 2 & 3: Data sukses dimuat, ATAU Empty State
            // =================================================================
            data: (categories) {
              
              // KONDISI 3: Empty state
              // Menampilkan UI khusus jika daftar kategori yang diterima dari database ternyata kosong.
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
                          // Form Upload Foto Nota
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: state.validationError != null && state.validationError!.contains('Foto') 
                                      ? Colors.red 
                                      : Colors.grey.shade400,
                                ),
                              ),
                              child: _imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade500),
                                        const SizedBox(height: 8),
                                        Text('Upload Foto Nota', style: TextStyle(color: Colors.grey.shade600)),
                                      ],
                                    ),
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
                  
                  // =================================================================
                  // KONDISI 6: Loading submit
                  // =================================================================
                  ElevatedButton(
                    // Ketika `isSubmitting` bernilai true, kita set onPressed menjadi `null`.
                    // Dalam Flutter, mengatur onPressed ke `null` akan otomatis men-disable tombol 
                    // (merubah warna jadi pudar dan menonaktifkan klik).
                    onPressed: state.isSubmitting ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    // Jika `isSubmitting` aktif, kita ubah teks menjadi Indikator Putaran.
                    child: state.isSubmitting 
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.receiptToEdit == null ? 'Simpan Nota' : 'Simpan Perubahan'),
                  ),

                  // =================================================================
                  // TOMBOL BANTU (DEBUG / SIMULASI) 
                  // Karena ini demonstrasi, kita tambahkan tombol bantu untuk mengetes Kondisi 3 dan 4.
                  // =================================================================
                  const SizedBox(height: 24),
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
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
