import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aquarium.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE Fish (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      color TEXT,
      speed REAL
    )
    ''');
  }

  Future<void> saveFish(List<Map<String, dynamic>> fishes) async {
    final db = await instance.database;
    await db.delete('Fish'); // Clear old data
    for (var fish in fishes) {
      await db.insert('Fish', fish);
    }
  }

  Future<List<Map<String, dynamic>>> loadFishes() async {
    final db = await instance.database;
    return await db.query('Fish');
  }

  Future<void> removeFishByColor(String color) async {
    final db = await instance.database;
    await db.delete(
      'Fish',
      where: 'color = ?',
      whereArgs: [color],
    );
  }
}
