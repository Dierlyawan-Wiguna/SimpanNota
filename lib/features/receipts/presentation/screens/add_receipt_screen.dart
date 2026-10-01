import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/category.dart';
import '../controllers/add_receipt_notifier.dart';

/// Screen untuk menambahkan nota baru. Menggunakan ConsumerStatefulWidget
/// karena kita butuh TextEditingController (Stateful) dan juga butuh
/// mengakses/mengamati state dari Riverpod (Consumer).
class AddReceiptScreen extends ConsumerStatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen> {
  // Controller untuk membaca inputan teks dari pengguna.
  final TextEditingController _nameController = TextEditingController();
  
  // State lokal UI untuk menyimpan kategori mana yang sedang dipilih dari Dropdown.
  Category? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Fungsi ini dipanggil ketika user menekan tombol "Simpan Nota".
  Future<void> _onSubmit() async {
    // Membaca object notifier untuk mengeksekusi logika submitReceipt.
    // Menggunakan ref.read() (bukan ref.watch) karena fungsi ini dipanggil 
    // dalam event callback (onPressed), bukan saat build method.
    final notifier = ref.read(addReceiptNotifierProvider.notifier);
    
    // Meneruskan data form dari UI ke layer Notifier/Controller untuk divalidasi dan diproses.
    final success = await notifier.submitReceipt(
      _nameController.text, 
      _selectedCategory,
    );

    // Cek mounted sebelum mengeksekusi aksi BuildContext setelah operasi asinkron (await).
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota berhasil disimpan!')),
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
        title: const Text('Tambah Nota'),
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
                  // Form Input Nama Barang
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Barang',
                      border: const OutlineInputBorder(),
                      
                      // KONDISI 5: Validasi form 
                      // Mengambil pesan error dari state (jika tidak null dan memuat kata kunci) 
                      // akan memicu TextField menampilkan underline dan teks merah secara otomatis.
                      errorText: state.validationError != null && state.validationError!.contains('Nama')
                          ? state.validationError
                          : null,
                    ),
                    onChanged: (_) {
                      // Hapus pesan error saat pengguna mulai memperbaiki ketikan/input.
                      ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Form Dropdown Kategori
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori Nota',
                      border: const OutlineInputBorder(),
                      
                      // KONDISI 5: Validasi form untuk dropdown
                      errorText: state.validationError != null && state.validationError!.contains('Kategori')
                          ? state.validationError
                          : null,
                    ),
                    hint: const Text('Pilih Kategori'),
                    items: categories.map((Category cat) {
                      return DropdownMenuItem<Category>(
                        value: cat,
                        child: Text(cat.label), // Contoh: "Elektronik", "Kendaraan"
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                      // Hapus pesan error saat user selesai memilih.
                      ref.read(addReceiptNotifierProvider.notifier).clearValidationError();
                    },
                  ),
                  
                  const Spacer(),
                  
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
                        : const Text('Simpan Nota'),
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
