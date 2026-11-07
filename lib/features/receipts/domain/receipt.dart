import 'category.dart';
import 'warranty_status.dart';

class Receipt {
  final int? id;
  final String productName;
  final Category category;
  final String storeName;
  final DateTime purchaseDate;
  final int warrantyMonths;
  final int warrantyDays;
  final String imagePath;

  Receipt({
    this.id,
    required this.productName,
    required this.category,
    required this.storeName,
    required this.purchaseDate,
    required this.warrantyMonths,
    this.warrantyDays = 0,
    required this.imagePath,
  });

  /// Menghitung tanggal kedaluwarsa secara presisi berdasarkan kombinasi bulan dan hari
  DateTime get expirationDate {
    final withMonths = DateTime(
      purchaseDate.year,
      purchaseDate.month + warrantyMonths,
      purchaseDate.day,
      purchaseDate.hour,
      purchaseDate.minute,
    );
    return withMonths.add(Duration(days: warrantyDays));
  }

  /// Status garansi dihitung dari tanggal kedaluwarsa presisi
  WarrantyStatus get status {
    final now = DateTime.now();
    final daysLeft = expirationDate.difference(now).inDays;

    if (daysLeft < 0) {
      return WarrantyStatus.expired;
    } else if (daysLeft <= 30) {
      return WarrantyStatus.expiringSoon;
    } else {
      return WarrantyStatus.active;
    }
  }

  /// Menghasilkan label teks durasi garansi yang rapi (contoh: '1 Bulan 15 Hari' atau '15 Hari' atau '12 Bulan')
  String get warrantyDurationLabel {
    if (warrantyMonths > 0 && warrantyDays > 0) {
      return '$warrantyMonths Bulan $warrantyDays Hari';
    } else if (warrantyMonths > 0) {
      return '$warrantyMonths Bulan';
    } else {
      return '$warrantyDays Hari';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'category': category.name, // save enum as string
      'storeName': storeName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'warrantyMonths': warrantyMonths,
      'warrantyDays': warrantyDays,
      'imagePath': imagePath,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] as int?,
      productName: map['productName'] as String,
      category: Category.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => Category.elektronik,
      ),
      storeName: map['storeName'] as String,
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      warrantyMonths: map['warrantyMonths'] as int? ?? 0,
      warrantyDays: map['warrantyDays'] as int? ?? 0,
      imagePath: map['imagePath'] as String,
    );
  }

  // API Integration: toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'category': category.name,
      'storeName': storeName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'warrantyMonths': warrantyMonths,
      'warrantyDays': warrantyDays,
      'imagePath': imagePath,
      'title': productName,
      'body': storeName,
      'userId': 1,
    };
  }

  // Supabase PostgreSQL mapping: toSupabaseMap
  Map<String, dynamic> toSupabaseMap({bool includeDays = true}) {
    return {
      if (id != null) 'id': id,
      'product_name': productName,
      'category': category.name.toLowerCase(),
      'store_name': storeName,
      'purchase_date': purchaseDate.toIso8601String().split('T').first,
      'warranty_months': warrantyMonths > 0 ? warrantyMonths : 1,
      if (includeDays && warrantyDays > 0) 'warranty_days': warrantyDays,
      'image_path': imagePath,
    };
  }

  // API Integration: fromJson dengan exception handling & multi-format
  factory Receipt.fromJson(Map<String, dynamic> json) {
    try {
      final rawCategory = (json['category'] ?? '').toString().toLowerCase();
      final dateRaw = json['purchase_date'] ?? json['purchaseDate'];
      final monthsRaw = json['warranty_months'] ?? json['warrantyMonths'];
      final daysRaw = json['warranty_days'] ?? json['warrantyDays'];
      final imageRaw = json['image_path'] ?? json['imagePath'] ?? '';

      return Receipt(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
        productName: (json['product_name'] ?? json['productName'] ?? json['title'] ?? 'Unknown Product').toString(),
        category: Category.values.firstWhere(
          (e) => e.name.toLowerCase() == rawCategory,
          orElse: () => Category.elektronik,
        ),
        storeName: (json['store_name'] ?? json['storeName'] ?? 'Unknown Store').toString(),
        purchaseDate: dateRaw != null 
            ? DateTime.tryParse(dateRaw.toString()) ?? DateTime.now()
            : DateTime.now(),
        warrantyMonths: monthsRaw != null 
            ? int.tryParse(monthsRaw.toString()) ?? 0
            : 0,
        warrantyDays: daysRaw != null
            ? int.tryParse(daysRaw.toString()) ?? 0
            : 0,
        imagePath: imageRaw.toString(),
      );
    } catch (e) {
      throw FormatException('Gagal melakukan parsing JSON API ke bentuk Receipt: $e');
    }
  }

  Receipt copyWith({
    int? id,
    String? productName,
    Category? category,
    String? storeName,
    DateTime? purchaseDate,
    int? warrantyMonths,
    int? warrantyDays,
    String? imagePath,
  }) {
    return Receipt(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      storeName: storeName ?? this.storeName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      warrantyDays: warrantyDays ?? this.warrantyDays,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
