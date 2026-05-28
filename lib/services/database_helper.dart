import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton helper for the local SQLite database.
///
/// Table: [tableTransactions]
///   id          – local autoincrement PK
///   budget_id   – name of the BudgetCategory (server-side ID not available yet)
///   type        – 'income' | 'expense'
///   amount      – double
///   item_name   – display name of the transaction
///   quantity    – int (always 1 for income)
///   notes       – optional free text
///   sync_status – 0 = pending upload, 1 = synced with server
class DatabaseHelper {
  static const _databaseName = 'vibe_budget.db';
  static const _databaseVersion = 1;
  static const tableTransactions = 'transactions';

  // ── Singleton ──────────────────────────────────────────────────────────────
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        budget_id   TEXT    NOT NULL,
        type        TEXT    NOT NULL,
        amount      REAL    NOT NULL,
        item_name   TEXT    NOT NULL,
        quantity    INTEGER NOT NULL DEFAULT 1,
        notes       TEXT,
        sync_status INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ── CRUD helpers ───────────────────────────────────────────────────────────

  /// Inserts a new transaction row.
  /// Returns the new row's local [id].
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(tableTransactions, row);
  }

  /// Returns every row whose [sync_status] is 0 (pending upload).
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await database;
    return db.query(
      tableTransactions,
      where: 'sync_status = ?',
      whereArgs: [0],
    );
  }

  /// Marks a single row as synced (sync_status = 1).
  Future<int> markAsSynced(int id) async {
    final db = await database;
    return db.update(
      tableTransactions,
      {'sync_status': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns all rows – useful for debugging.
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return db.query(tableTransactions, orderBy: 'id DESC');
  }
}
