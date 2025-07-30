import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/offline_location.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'location_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_locations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        placeName TEXT,
        address TEXT,
        accuracy REAL,
        isSynced INTEGER DEFAULT 0
      )
    ''');
  }

  // Insert location
  Future<int> insertLocation(OfflineLocation location) async {
    final db = await database;
    return await db.insert('offline_locations', location.toMap());
  }

  // Get all unsynced locations
  Future<List<OfflineLocation>> getUnsyncedLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_locations',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) {
      return OfflineLocation.fromMap(maps[i]);
    });
  }

  // Get all locations (for history)
  Future<List<OfflineLocation>> getAllLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_locations',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return OfflineLocation.fromMap(maps[i]);
    });
  }

  // Get locations by date
  Future<List<OfflineLocation>> getLocationsByDate(DateTime date) async {
    final db = await database;
    
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_locations',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ],
      orderBy: 'timestamp ASC',
    );
    
    return List.generate(maps.length, (i) {
      return OfflineLocation.fromMap(maps[i]);
    });
  }

  // Mark location as synced
  Future<int> markLocationAsSynced(int id) async {
    final db = await database;
    return await db.update(
      'offline_locations',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete synced locations (optional cleanup)
  Future<int> deleteSyncedLocations() async {
    final db = await database;
    return await db.delete(
      'offline_locations',
      where: 'isSynced = ?',
      whereArgs: [1],
    );
  }

  // Get database size info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM offline_locations');
    final unsyncedCount = await db.rawQuery('SELECT COUNT(*) as count FROM offline_locations WHERE isSynced = 0');
    
    return {
      'totalLocations': count.first['count'],
      'unsyncedLocations': unsyncedCount.first['count'],
    };
  }
}