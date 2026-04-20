import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'optiflow_local.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Products Table
    await db.execute('''
      CREATE TABLE products(
        product_id TEXT PRIMARY KEY,
        business_id TEXT,
        name TEXT,
        selling_price REAL,
        production_cost REAL,
        unit TEXT,
        profit_margin REAL,
        image_url TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    // Locations Table
    await db.execute('''
      CREATE TABLE locations(
        location_id TEXT PRIMARY KEY,
        business_id TEXT,
        name TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        type TEXT,
        supply_quantity REAL,
        demand_quantity REAL,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    // Resources Table
    await db.execute('''
      CREATE TABLE resources(
        resource_id TEXT PRIMARY KEY,
        business_id TEXT,
        name TEXT,
        available_quantity REAL,
        unit TEXT,
        constraint_type TEXT DEFAULT 'LE',
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    // Product Resources Table
    await db.execute('''
      CREATE TABLE product_resources(
        product_id TEXT,
        resource_id TEXT,
        quantity_required REAL,
        PRIMARY KEY (product_id, resource_id)
      )
    ''');

    // Budgets Table
    await db.execute('''
      CREATE TABLE budgets(
        budget_id TEXT PRIMARY KEY,
        business_id TEXT,
        total_amount REAL,
        departmental_allocation TEXT,
        regional_allocation TEXT,
        min_profit_target REAL,
        max_labor_cost REAL,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    // Optimization Results Table
    await db.execute('''
      CREATE TABLE optimization_results(
        result_id TEXT PRIMARY KEY,
        business_id TEXT,
        type TEXT,
        result_data TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT,
        collection TEXT,
        data TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN synced INTEGER DEFAULT 1');
    }
    if (oldVersion < 3) {
      // Add missing columns for v3
      try {
        await db.execute('ALTER TABLE products ADD COLUMN image_url TEXT');
      } catch (_) {}
      
      try {
        await db.execute('ALTER TABLE resources ADD COLUMN constraint_type TEXT DEFAULT "LE"');
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_resources(
          product_id TEXT,
          resource_id TEXT,
          quantity_required REAL,
          PRIMARY KEY (product_id, resource_id)
        )
      ''');
    }
  }

  // Generic helper methods
  Future<int> insert(String table, Map<String, dynamic> data) async {
    Database db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    Database db = await database;
    return await db.query(table);
  }

  Future<int> delete(String table, String idColumn, String idValue) async {
    Database db = await database;
    return await db.delete(table, where: '$idColumn = ?', whereArgs: [idValue]);
  }

  Future<void> clearTable(String table) async {
    Database db = await database;
    await db.delete(table);
  }
}
