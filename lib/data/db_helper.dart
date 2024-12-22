import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Singleton class for DBHelper
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  DBHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'healthcare.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fullName TEXT,
            email TEXT UNIQUE,
            phoneNumber TEXT,
            password TEXT
          )
        ''');
      },
    );
  }

  // Insert user data
  Future<void> insertUser(Map<String, dynamic> userData) async {
    final db = await database;
    try {
      await db.insert('users', userData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if(e is DatabaseException && e.isUniqueConstraintError()) {
        throw Exception('Email already exists. Please use a different email');
      }
      else {
        throw Exception('An error occirred while inserting the user');
      }
    }
  }
  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }
}
