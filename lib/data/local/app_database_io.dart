import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

/// Accès sqflite (Android / iOS / desktop avec FFI si configuré).
///
/// Configuration seule : ouverture du fichier + [onCreate] / [onUpgrade].
/// Aucun DAO / CRUD métier pour l'instant — les repositories mock restent
/// la source de vérité jusqu'à la prochaine étape.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  bool get isSupported => true;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, DatabaseConstants.fileName);

    return openDatabase(
      path,
      version: DatabaseConstants.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Schéma initial (version 1) — tables vides, prêtes pour les DAO.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.users} (
        id TEXT PRIMARY KEY NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        password_hash TEXT,
        member_since TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.cars} (
        id TEXT PRIMARY KEY NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        category TEXT NOT NULL,
        price_per_day REAL NOT NULL,
        transmission TEXT NOT NULL,
        fuel TEXT NOT NULL,
        seats INTEGER NOT NULL,
        city TEXT NOT NULL,
        available INTEGER NOT NULL DEFAULT 1,
        image_urls TEXT,
        payload_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.reservations} (
        id TEXT PRIMARY KEY NOT NULL,
        user_id TEXT NOT NULL,
        car_id TEXT NOT NULL,
        status TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        pickup_city TEXT NOT NULL,
        return_city TEXT NOT NULL,
        total REAL NOT NULL,
        payload_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.users} (id),
        FOREIGN KEY (car_id) REFERENCES ${DatabaseConstants.cars} (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.payments} (
        id TEXT PRIMARY KEY NOT NULL,
        reservation_id TEXT NOT NULL,
        method TEXT NOT NULL,
        status TEXT NOT NULL,
        amount REAL NOT NULL,
        paid_at TEXT,
        payload_json TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (reservation_id) REFERENCES ${DatabaseConstants.reservations} (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.auctions} (
        id TEXT PRIMARY KEY NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        starting_price REAL NOT NULL,
        min_increment REAL NOT NULL,
        start_at TEXT NOT NULL,
        end_at TEXT NOT NULL,
        status TEXT,
        cancelled INTEGER NOT NULL DEFAULT 0,
        payload_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.bids} (
        id TEXT PRIMARY KEY NOT NULL,
        auction_id TEXT NOT NULL,
        bidder_name TEXT NOT NULL,
        amount REAL NOT NULL,
        bid_at TEXT NOT NULL,
        is_current_user INTEGER NOT NULL DEFAULT 0,
        is_simulated INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (auction_id) REFERENCES ${DatabaseConstants.auctions} (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.quizResults} (
        id TEXT PRIMARY KEY NOT NULL,
        user_id TEXT,
        quiz_id TEXT NOT NULL,
        score INTEGER NOT NULL,
        total INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        payload_json TEXT
      )
    ''');

    await _createRoadSignsTable(db);
    await _createExamsTables(db);
  }

  Future<void> _createRoadSignsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.roadSigns} (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        shape TEXT NOT NULL,
        meaning TEXT NOT NULL,
        advice TEXT NOT NULL,
        glyph TEXT NOT NULL,
        trust TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createExamsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.exams} (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        passing_percent INTEGER NOT NULL DEFAULT 70,
        is_published INTEGER NOT NULL DEFAULT 1,
        is_final INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.examQuestions} (
        id TEXT PRIMARY KEY NOT NULL,
        exam_id TEXT NOT NULL,
        question TEXT NOT NULL,
        options_json TEXT NOT NULL,
        correct_index INTEGER NOT NULL,
        explanation TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (exam_id) REFERENCES ${DatabaseConstants.exams} (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createRoadSignsTable(db);
    }
    if (oldVersion < 3) {
      await _createExamsTables(db);
    }
    if (oldVersion < 4) {
      // Retire les données de démo préremplies ; l'auth reste hors SQLite.
      await db.delete(DatabaseConstants.examQuestions);
      await db.delete(DatabaseConstants.exams);
      await db.delete(DatabaseConstants.roadSigns);
      await db.delete(DatabaseConstants.cars);
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) return;
    await db.close();
    _db = null;
  }
}
