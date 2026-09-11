import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/app_settings.dart';
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
      version: 3,
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
            exercise_minutes INTEGER,
            water_oz REAL,
            calories REAL
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
        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY,
            protein_bar_calories REAL,
            protein_bar_protein_grams REAL,
            protein_drink_calories REAL,
            protein_drink_protein_grams REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE entries ADD COLUMN water_oz REAL');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE entries ADD COLUMN calories REAL');
          await db.execute('''
            CREATE TABLE settings (
              id INTEGER PRIMARY KEY,
              protein_bar_calories REAL,
              protein_bar_protein_grams REAL,
              protein_drink_calories REAL,
              protein_drink_protein_grams REAL
            )
          ''');
        }
      },
    );
  }

  Future<AppSettings> getSettings() async {
    final db = await database;
    final rows = await db.query('settings', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return AppSettings.defaults;
    final r = rows.first;
    return AppSettings(
      proteinBar: ProteinDefaults(
        calories: (r['protein_bar_calories'] as num?)?.toDouble() ??
            AppSettings.defaults.proteinBar.calories,
        proteinGrams: (r['protein_bar_protein_grams'] as num?)?.toDouble() ??
            AppSettings.defaults.proteinBar.proteinGrams,
      ),
      proteinDrink: ProteinDefaults(
        calories: (r['protein_drink_calories'] as num?)?.toDouble() ??
            AppSettings.defaults.proteinDrink.calories,
        proteinGrams: (r['protein_drink_protein_grams'] as num?)?.toDouble() ??
            AppSettings.defaults.proteinDrink.proteinGrams,
      ),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'id': 1,
        'protein_bar_calories': settings.proteinBar.calories,
        'protein_bar_protein_grams': settings.proteinBar.proteinGrams,
        'protein_drink_calories': settings.proteinDrink.calories,
        'protein_drink_protein_grams': settings.proteinDrink.proteinGrams,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertEntry(TimelineEntry entry) async {
    final db = await database;
    final map = entry.toMap()..remove('id');
    return db.insert('entries', map);
  }

  Future<int> updateEntry(TimelineEntry entry) async {
    final db = await database;
    final map = entry.toMap()..remove('id');
    return db.update('entries', map, where: 'id = ?', whereArgs: [entry.id]);
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

  /// Most recent 'bed' entry strictly before [time] — used to estimate sleep
  /// duration even when bed time fell on the previous day.
  Future<TimelineEntry?> mostRecentBedBefore(DateTime time) async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: 'type = ? AND timestamp < ?',
      whereArgs: [EntryType.bed.name, time.toIso8601String()],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TimelineEntry.fromMap(rows.first);
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
