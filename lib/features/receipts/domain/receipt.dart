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
