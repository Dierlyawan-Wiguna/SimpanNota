import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/category.dart';
import '../../services/receipt_repository.dart';

import 'receipt_list_notifier.dart';

/// State untuk menyimpan seluruh kondisi UI pada halaman Tambah Nota.
/// Penggunaan class State memisahkan data spesifik UI agar tertata rapi dan immutable.
class AddReceiptState {
  // Menggunakan AsyncValue dari Riverpod untuk mengelola state Asinkron (Kondisi 1, 2, 3, dan 4).
  // - AsyncValue.loading() mewakili kondisi ke-1 (Initial loading).
  // - AsyncValue.data() mewakili kondisi ke-2 (Sukses) atau ke-3 (Empty State, jika List kosong).
  // - AsyncValue.error() mewakili kondisi ke-4 (Error State).
  final AsyncValue<List<Category>> categoriesState;
  
  // Status boolean ini mengatur kondisi ke-6 (Loading Submit). 
  // Jika true, tombol simpan akan berputar dan didisable.
  final bool isSubmitting;
  
  // Menyimpan string pesan error untuk kondisi ke-5 (Validasi form). 
  // Jika null, tidak ada error validasi.
  final String? validationError;

  AddReceiptState({
    required this.categoriesState,
    this.isSubmitting = false,
    this.validationError,
  });

  /// Method copyWith merupakan pola standar dalam state management immutable.
  /// Ini membantu menghasilkan salinan State baru dengan memperbarui properti yang dibutuhkan saja.
  AddReceiptState copyWith({
    AsyncValue<List<Category>>? categoriesState,
    bool? isSubmitting,
    String? validationError,
    bool clearValidationError = false, // Flag khusus untuk mereset pesan error validasi ke null.
  }) {
    return AddReceiptState(
      categoriesState: categoriesState ?? this.categoriesState,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      validationError: clearValidationError ? null : (validationError ?? this.validationError),
    );
  }
}

/// Notifier yang bertugas sebagai ViewModel / Controller untuk AddReceiptScreen.
/// Di sini seluruh logika dan alur (flow) validasi, pengambilan data, serta penyimpanan ditangani.
class AddReceiptNotifier extends Notifier<AddReceiptState> {
  @override
  AddReceiptState build() {
    // Pada saat pertama kali Notifier dibuat (screen diakses), 
    // panggil fetchCategories untuk memulai proses pengambilan data dari repository.
    Future.microtask(() => fetchCategories());
    
    // Inisialisasi awal dengan state loading (Kondisi UI 1: Initial Loading)
    return AddReceiptState(
      categoriesState: const AsyncValue.loading(),
    );
  }

  /// Fungsi untuk mengambil data kategori dari repository.
  /// Menerima parameter opsional untuk memudahkan kita mendemonstrasikan Empty/Error State.
  Future<void> fetchCategories({bool simulateError = false, bool simulateEmpty = false}) async {
    // Memperbarui UI menjadi status loading setiap kali fetching dipanggil ulang.
    state = state.copyWith(categoriesState: const AsyncValue.loading());
    
    try {
      final repository = ref.read(receiptRepositoryProvider);
      // Memanggil fungsi fetch pada repository
      final categories = await repository.fetchCategories(
        simulateError: simulateError,
        simulateEmpty: simulateEmpty,
      );
      
      // Jika berhasil, perbarui state kategori dengan AsyncValue.data()
      // Riverpod dan UI nantinya bisa membaca apakah List-nya ada isi atau kosong.
      state = state.copyWith(categoriesState: AsyncValue.data(categories));
    } catch (e, stack) {
      // Jika terjadi kesalahan saat fetching (Kondisi UI 4: Error State), 
      // tangkap pesan error dan kembalikan state AsyncValue.error().
      state = state.copyWith(categoriesState: AsyncValue.error(e, stack));
    }
  }

  /// Fungsi untuk memvalidasi dan menyimpan data formulir input Nota Baru.
  /// Mengembalikan true apabila proses simpan berjalan sukses, atau false jika validasi gagal.
  Future<bool> submitReceipt({
    int? editId,
    required String productName,
    required Category? selectedCategory,
    required String storeName,
    required DateTime? purchaseDate,
    required String warrantyMonths,
    required String? imagePath,
  }) async {
    // 5. Validasi Form
    if (productName.trim().isEmpty) {
      state = state.copyWith(validationError: 'Nama barang tidak boleh kosong.');
      return false;
    }
    
    if (selectedCategory == null) {
      state = state.copyWith(validationError: 'Kategori harus dipilih terlebih dahulu.');
      return false;
    }

    if (storeName.trim().isEmpty) {
      state = state.copyWith(validationError: 'Nama toko tidak boleh kosong.');
      return false;
    }

    if (purchaseDate == null) {
      state = state.copyWith(validationError: 'Tanggal beli harus diisi.');
      return false;
    }

    if (warrantyMonths.trim().isEmpty || int.tryParse(warrantyMonths.trim()) == null) {
      state = state.copyWith(validationError: 'Durasi garansi (bulan) tidak valid.');
      return false;
    }

    if (imagePath == null || imagePath.isEmpty) {
      state = state.copyWith(validationError: 'Foto nota harus dilampirkan.');
      return false;
    }

    // Jika semua validasi lolos, bersihkan error sebelumnya.
    state = state.copyWith(clearValidationError: true);

    // 6. Loading submit
    // Perbarui isSubmitting menjadi true agar tombol form di UI disable dan menunjukkan animasi loading.
    state = state.copyWith(isSubmitting: true);
    
    try {
      final repository = ref.read(receiptRepositoryProvider);
      
      if (editId != null) {
        // Lakukan proses update data
        await repository.updateReceipt(
          id: editId,
          namaBarang: productName,
          kategori: selectedCategory,
          namaToko: storeName,
          tanggalBeli: purchaseDate,
          durasiGaransiBulan: int.parse(warrantyMonths.trim()),
          fotoPath: imagePath,
        );
      } else {
        // Lakukan proses simpan data baru
        await repository.saveReceipt(
          namaBarang: productName,
          kategori: selectedCategory,
          namaToko: storeName,
          tanggalBeli: purchaseDate,
          durasiGaransiBulan: int.parse(warrantyMonths.trim()),
          fotoPath: imagePath,
        );
      }
      
      // Refresh list nota di halaman depan
      ref.read(receiptListProvider.notifier).loadReceipts();

      // Setelah sukses disimpan, setel kembali isSubmitting.
      state = state.copyWith(isSubmitting: false);
      return true; // Menandakan bahwa proses submit sukses dan UI bisa bernavigasi/keluar (Pop screen).
    } catch (e) {
      // Jika terjadi error dari layer network saat menyimpan, tampilkan error validasi (untuk di-handle oleh UI).
      state = state.copyWith(
        isSubmitting: false,
        validationError: 'Gagal menyimpan nota: $e'
      );
      return false;
    }
  }
  
  /// Helper ini dapat dipanggil (misalnya di onChanged TextField) 
  /// untuk menghapus error warna merah jika pengguna mulai mengetik atau membenarkan inputan.
  void clearValidationError() {
    if (state.validationError != null) {
      state = state.copyWith(clearValidationError: true);
    }
  }
}

// Provider Riverpod untuk `AddReceiptNotifier`.
// Digunakan `autoDispose` agar instance dan memory dari Controller dihancurkan 
// saat `AddReceiptScreen` tertutup (destroyed) dan tidak memakan memori berlebih.
final addReceiptNotifierProvider = NotifierProvider.autoDispose<AddReceiptNotifier, AddReceiptState>(AddReceiptNotifier.new);
