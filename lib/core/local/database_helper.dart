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
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE receipts ADD COLUMN warrantyDays INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
        }
        if (oldVersion < 3) {
          await _createSystemLogsTable(db);
        }
      },
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE receipts ADD COLUMN warrantyDays INTEGER NOT NULL DEFAULT 0');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE receipts ADD COLUMN warrantyCardPath TEXT');
        } catch (_) {}
        await _createSystemLogsTable(db);
      },
    );
  }

  Future<void> _createSystemLogsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS system_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL,
  level TEXT NOT NULL,
  tag TEXT NOT NULL,
  message TEXT NOT NULL,
  error TEXT,
  stackTrace TEXT
)
''');
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
  warrantyDays INTEGER NOT NULL DEFAULT 0,
  imagePath TEXT NOT NULL,
  warrantyCardPath TEXT
)
''');
    await _createSystemLogsTable(db);
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

  // --- Runtime System Logs Management (Pertemuan 10) ---

  Future<int> insertSystemLog(Map<String, dynamic> logMap) async {
    final db = await instance.database;
    final id = await db.insert('system_logs', logMap);

    // Otomatis rotasi log: Pertahankan maksimal 500 entri terbaru
    await db.rawDelete('''
      DELETE FROM system_logs 
      WHERE id NOT IN (
        SELECT id FROM system_logs ORDER BY id DESC LIMIT 500
      )
    ''');

    return id;
  }

  Future<List<Map<String, dynamic>>> getSystemLogs({
    String? level,
    int limit = 500,
  }) async {
    final db = await instance.database;
    final where = (level != null && level.isNotEmpty && level != 'ALL')
        ? 'level = ?'
        : null;
    final whereArgs = where != null ? [level] : null;

    return await db.query(
      'system_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
      limit: limit,
    );
  }

  Future<int> clearSystemLogs() async {
    final db = await instance.database;
    return await db.delete('system_logs');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
