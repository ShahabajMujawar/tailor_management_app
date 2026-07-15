import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';

/// Service responsible for managing SQLite database creation,
/// configuration, upgrades, and opening connections.
class DatabaseService {
  final Logger _logger;
  Database? _database;

  DatabaseService({Logger? logger})
      : _logger = logger ?? Logger();

  /// Gets the active database instance. If not initialized, opens it.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'tailor_management_system.db');
    _logger.i('Initializing SQLite Database at: $pathString');

    final db = await openDatabase(
      pathString,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );

    await _seedDummyUser(db);
    return db;
  }

  Future<void> _seedDummyUser(Database db) async {
    final results = await db.rawQuery(
      'SELECT id FROM users WHERE username = ? LIMIT 1',
      ['admin@tailorpro.com'],
    );

    if (results.isEmpty) {
      _logger.i('Seeding dummy user...');
      await db.rawInsert(
        'INSERT INTO users (username, password_hash, role, created_at) VALUES (?, ?, ?, ?)',
        [
          'admin@tailorpro.com',
          '4f978b3ceefd1c1f18017dabc6fc3a42ff48bfbe30a576fd97316a3f24e47a34', // password123
          'admin',
          DateTime.now().toIso8601String()
        ],
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable Foreign Key support in SQLite
    await db.execute('PRAGMA foreign_keys = ON');
    _logger.i('SQLite foreign keys support enabled.');
  }

  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database tables...');

    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        mobile_number TEXT UNIQUE NOT NULL,
        alternate_number TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. Orders Table
    await db.execute('''
      CREATE TABLE orders (
        order_id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER NOT NULL,
        order_date TEXT NOT NULL,
        delivery_date TEXT NOT NULL,
        status TEXT NOT NULL,
        remarks TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
      )
    ''');

    // 4. Garments Table
    await db.execute('''
      CREATE TABLE garments (
        garment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        garment_type TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
      )
    ''');

    // 5. Measurements Table
    await db.execute('''
      CREATE TABLE measurements (
        measurement_id INTEGER PRIMARY KEY AUTOINCREMENT,
        garment_id INTEGER NOT NULL,
        measurement_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (garment_id) REFERENCES garments(garment_id) ON DELETE CASCADE
      )
    ''');

    // 6. Preferences Table
    await db.execute('''
      CREATE TABLE preferences (
        preference_id INTEGER PRIMARY KEY AUTOINCREMENT,
        garment_id INTEGER NOT NULL,
        preference_json TEXT NOT NULL,
        FOREIGN KEY (garment_id) REFERENCES garments(garment_id) ON DELETE CASCADE
      )
    ''');

    // 7. Settings Table
    await db.execute('''
      CREATE TABLE settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
      )
    ''');

    // Create Indexes for search optimization
    _logger.i('Creating database indexes...');
    await db.execute('CREATE INDEX idx_customers_mobile ON customers(mobile_number)');
    await db.execute('CREATE INDEX idx_orders_receipt ON orders(receipt_number)');
    await db.execute('CREATE INDEX idx_orders_customer ON orders(customer_id)');
    await db.execute('CREATE INDEX idx_orders_delivery ON orders(delivery_date)');
    await db.execute('CREATE INDEX idx_orders_status ON orders(status)');

    _logger.i('Database initialization completed successfully.');
  }

  /// Helper to close the database when application shuts down.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      _logger.i('SQLite database connection closed.');
    }
  }
}
