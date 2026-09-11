import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/timeline_entry.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'timeline.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            protein_name TEXT,
            protein_grams REAL,
            veggie_name TEXT,
            veggie_grams REAL,
            exercise_description TEXT,
            exercise_minutes INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE protein_options (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE veggie_options (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertEntry(TimelineEntry entry) async {
    final db = await database;
    final map = entry.toMap()..remove('id');
    return db.insert('entries', map);
  }

  Future<List<TimelineEntry>> entriesForDay(DateTime day) async {
    final db = await database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    return rows.map((r) => TimelineEntry.fromMap(r)).toList();
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addProteinOption(String name) async {
    final db = await database;
    await db.insert('protein_options', {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> addVeggieOption(String name) async {
    final db = await database;
    await db.insert('veggie_options', {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> proteinOptions() async {
    final db = await database;
    final rows = await db.query('protein_options', orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<List<String>> veggieOptions() async {
    final db = await database;
    final rows = await db.query('veggie_options', orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }
}
