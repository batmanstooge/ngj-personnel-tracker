import 'package:location_ui/models/local_location.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';



class LocalDbService {
  static Database? _database; // Private static instance of the database

  // Getter to provide the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb(); 
    return _database!;
  }

  // Initializes the database
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'personal_tracker.db');

    return await openDatabase(
      path,
      version: 1, 
      onCreate: (db, version) async {
        
        await db.execute('''
          CREATE TABLE locations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Insert a new location into the database
  Future<void> insertLocation(LocalLocation location) async {
    final db = await database;
    await db.insert(
      'locations',
      location.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace, 
    );
    print('Location saved to local DB: ${location.latitude}, ${location.longitude}');
  }

  // Retrieve all pending locations from the database
  Future<List<LocalLocation>> getPendingLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('locations', orderBy: 'timestamp ASC'); // Order oldest first
    return List.generate(maps.length, (i) {
      return LocalLocation.fromMap(maps[i]);
    });
  }

  // Delete a location by its ID after successful sync
  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Location deleted from local DB: ID $id');
  }

  // Clear all locations from the database 
  Future<void> clearAllLocations() async {
    final db = await database;
    await db.delete('locations');
    print('All local locations cleared.');
  }

  // Close the database 
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}