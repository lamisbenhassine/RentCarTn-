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
    await _addUserProfileColumns(db);
    await _createComplaintsTable(db);
  }

  /// Version 7 : réclamations. Colonnes indexées pour les listes / filtres,
  /// et [payload_json] = réclamation complète (historique, photos…), comme
  /// pour les voitures. Supprimer un compte supprime ses réclamations.
  Future<void> _createComplaintsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.complaints} (
        id TEXT PRIMARY KEY NOT NULL,
        reference TEXT NOT NULL UNIQUE,
        user_id TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        is_urgent INTEGER NOT NULL DEFAULT 0,
        reservation_id TEXT,
        auction_id TEXT,
        title TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES ${DatabaseConstants.users} (id)
          ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_complaints_user '
      'ON ${DatabaseConstants.complaints} (user_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_complaints_status '
      'ON ${DatabaseConstants.complaints} (status)',
    );
  }

  /// Version 5 : colonnes de profil de la table users.
  /// Utilisé à l'installation neuve et à la migration 4 → 5.
  static const List<String> _userProfileColumns = [
    'cin TEXT',
    'licence_number TEXT',
    'city TEXT',
    'address TEXT',
    'birth_date TEXT',
    'avatar_url TEXT',
    'public_username TEXT',
    'latitude REAL',
    'longitude REAL',
    'licence_expiry TEXT',
    'trust_score INTEGER NOT NULL DEFAULT 50',
    // Version 6 : 0 = e-mail à vérifier, 1 = vérifié.
    'email_verified INTEGER NOT NULL DEFAULT 0',
  ];

  Future<void> _addUserProfileColumns(Database db) async {
    final info = await db.rawQuery(
      'PRAGMA table_info(${DatabaseConstants.users})',
    );
    final existing = info.map((c) => c['name']! as String).toSet();

    for (final column in _userProfileColumns) {
      final name = column.split(' ').first;
      if (existing.contains(name)) continue;
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.users} ADD COLUMN $column',
      );
    }
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
    if (oldVersion < 5) {
      await _addUserProfileColumns(db);
    }
    if (oldVersion < 6) {
      await _addUserProfileColumns(db); // ajoute email_verified
      // Comptes créés avant la vérification : considérés comme vérifiés,
      // pour ne pas bloquer les utilisateurs existants.
      await db.update(DatabaseConstants.users, {'email_verified': 1});
    }
    if (oldVersion < 7) {
      await _createComplaintsTable(db);
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) return;
    await db.close();
    _db = null;
  }
}
