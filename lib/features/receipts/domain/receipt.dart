import 'category.dart';
import 'warranty_status.dart';

class Receipt {
  final int? id;
  final String productName;
  final Category category;
  final String storeName;
  final DateTime purchaseDate;
  final int warrantyMonths;
  final String imagePath;

  Receipt({
    this.id,
    required this.productName,
    required this.category,
    required this.storeName,
    required this.purchaseDate,
    required this.warrantyMonths,
    required this.imagePath,
  });

  WarrantyStatus get status {
    final now = DateTime.now();
    final expirationDate = purchaseDate.add(Duration(days: warrantyMonths * 30));
    final daysLeft = expirationDate.difference(now).inDays;

    if (daysLeft < 0) {
      return WarrantyStatus.expired;
    } else if (daysLeft <= 30) {
      return WarrantyStatus.expiringSoon;
    } else {
      return WarrantyStatus.active;
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
      warrantyMonths: map['warrantyMonths'] as int,
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
      'imagePath': imagePath,
      // Dukungan sementara untuk jsonplaceholder
      'title': productName,
      'body': storeName,
      'userId': 1,
    };
  }

  // Supabase PostgreSQL mapping: toSupabaseMap
  Map<String, dynamic> toSupabaseMap() {
    return {
      if (id != null) 'id': id,
      'product_name': productName,
      'category': category.name.toLowerCase(),
      'store_name': storeName,
      'purchase_date': purchaseDate.toIso8601String().split('T').first,
      'warranty_months': warrantyMonths,
      'image_path': imagePath,
    };
  }

  // API Integration: fromJson dengan exception handling & multi-format (camelCase & snake_case)
  factory Receipt.fromJson(Map<String, dynamic> json) {
    try {
      final rawCategory = (json['category'] ?? '').toString().toLowerCase();
      final dateRaw = json['purchase_date'] ?? json['purchaseDate'];
      final monthsRaw = json['warranty_months'] ?? json['warrantyMonths'];
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
    String? imagePath,
  }) {
    return Receipt(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      storeName: storeName ?? this.storeName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
