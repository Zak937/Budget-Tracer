import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class AppDatabase {
  AppDatabase({Database? database}) : _database = database;

  static final AppDatabase instance = AppDatabase();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final filePath = p.join(await getDatabasesPath(), 'budget_mate.db');
    _database = await openDatabase(
      filePath,
      version: 1,
      onCreate: _createSchema,
    );
    return _database!;
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
      amount REAL NOT NULL CHECK(amount > 0),
      category TEXT NOT NULL,
      description TEXT NOT NULL,
      date TEXT NOT NULL,
      note TEXT NOT NULL DEFAULT ''
    )''');
    await db.execute('''CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,
      amount REAL NOT NULL CHECK(amount > 0),
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      CHECK(end_date >= start_date)
    )''');
    await db.execute('''CREATE TABLE savings_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      target_amount REAL NOT NULL CHECK(target_amount > 0),
      saved_amount REAL NOT NULL DEFAULT 0 CHECK(saved_amount >= 0),
      target_date TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT ''
    )''');
    await db.execute('''CREATE TABLE profile (
      id INTEGER PRIMARY KEY CHECK(id = 1),
      name TEXT NOT NULL,
      currency TEXT NOT NULL,
      monthly_income REAL NOT NULL DEFAULT 0,
      monthly_budget REAL NOT NULL DEFAULT 0
    )''');
    await db.execute(
      'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await db.insert('profile', const UserProfile().toMap());
    await db.insert('settings', {'key': 'theme', 'value': 'system'});
    await db.insert('settings', {
      'key': 'onboarding_completed',
      'value': 'false',
    });
    await db.insert('settings', {
      'key': 'notifications_enabled',
      'value': 'true',
    });
    await db.execute(
      'CREATE INDEX transactions_date_idx ON transactions(date DESC)',
    );
    await db.execute(
      'CREATE INDEX transactions_category_idx ON transactions(category)',
    );
  }

  Future<List<MoneyTransaction>> transactions() async =>
      (await (await database).query(
        'transactions',
        orderBy: 'date DESC, id DESC',
      )).map(MoneyTransaction.fromMap).toList();

  Future<int> saveTransaction(MoneyTransaction item) async {
    final db = await database;
    return item.id == null
        ? db.insert('transactions', item.toMap()..remove('id'))
        : db.update(
            'transactions',
            item.toMap()..remove('id'),
            where: 'id = ?',
            whereArgs: [item.id],
          );
  }

  Future<void> deleteTransaction(int id) async =>
      (await database).delete('transactions', where: 'id = ?', whereArgs: [id]);

  Future<List<Budget>> budgets() async => (await (await database).query(
    'budgets',
    orderBy: 'start_date DESC',
  )).map(Budget.fromMap).toList();

  Future<int> saveBudget(Budget item) async {
    final db = await database;
    return item.id == null
        ? db.insert('budgets', item.toMap()..remove('id'))
        : db.update(
            'budgets',
            item.toMap()..remove('id'),
            where: 'id = ?',
            whereArgs: [item.id],
          );
  }

  Future<void> deleteBudget(int id) async =>
      (await database).delete('budgets', where: 'id = ?', whereArgs: [id]);

  Future<List<SavingsGoal>> goals() async => (await (await database).query(
    'savings_goals',
    orderBy: 'target_date',
  )).map(SavingsGoal.fromMap).toList();

  Future<int> saveGoal(SavingsGoal item) async {
    final db = await database;
    return item.id == null
        ? db.insert('savings_goals', item.toMap()..remove('id'))
        : db.update(
            'savings_goals',
            item.toMap()..remove('id'),
            where: 'id = ?',
            whereArgs: [item.id],
          );
  }

  Future<void> deleteGoal(int id) async => (await database).delete(
    'savings_goals',
    where: 'id = ?',
    whereArgs: [id],
  );

  Future<UserProfile> profile() async {
    final rows = await (await database).query('profile', where: 'id = 1');
    return rows.isEmpty ? const UserProfile() : UserProfile.fromMap(rows.first);
  }

  Future<void> saveProfile(UserProfile profile) async =>
      (await database).insert(
        'profile',
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<String> setting(String key, [String fallback = '']) async {
    final rows = await (await database).query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? fallback : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async =>
      (await database).insert('settings', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('savings_goals');
      await txn.update('profile', const UserProfile().toMap(), where: 'id = 1');
    });
  }

  Future<void> importTransactions(List<MoneyTransaction> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final item in items) {
        final date =
            '${item.date.year.toString().padLeft(4, '0')}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
        final duplicate = await txn.rawQuery(
          'SELECT 1 FROM transactions WHERE type = ? AND amount = ? AND category = ? AND description = ? AND date(date) = ? AND note = ? LIMIT 1',
          [
            item.type.name,
            item.amount,
            item.category,
            item.description,
            date,
            item.note,
          ],
        );
        if (duplicate.isNotEmpty) continue;
        await txn.insert('transactions', item.toMap()..remove('id'));
      }
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
