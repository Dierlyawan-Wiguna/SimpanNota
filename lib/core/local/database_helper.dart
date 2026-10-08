import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/receipts/domain/receipt.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('receipts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE receipts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  productName TEXT NOT NULL,
  category TEXT NOT NULL,
  storeName TEXT NOT NULL,
  purchaseDate TEXT NOT NULL,
  warrantyMonths INTEGER NOT NULL,
  imagePath TEXT NOT NULL
)
''');
  }

  Future<Receipt> insertReceipt(Receipt receipt) async {
    final db = await instance.database;
    final id = await db.insert('receipts', receipt.toMap());
    return receipt.copyWith(id: id);
  }

  Future<List<Receipt>> getReceipts() async {
    final db = await instance.database;
    final orderBy = 'purchaseDate DESC';
    final result = await db.query('receipts', orderBy: orderBy);
    return result.map((json) => Receipt.fromMap(json)).toList();
  }

  Future<int> updateReceipt(Receipt receipt) async {
    final db = await instance.database;
    return db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<int> deleteReceipt(int id) async {
    final db = await instance.database;
    return await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
