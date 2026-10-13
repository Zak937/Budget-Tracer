import 'package:budget_mate/data/database/app_database.dart';
import 'package:budget_mate/data/models/models.dart';
import 'package:budget_mate/providers/budget_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late BudgetProvider provider;
  late AppDatabase database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final memoryDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, amount REAL NOT NULL CHECK(amount > 0), category TEXT NOT NULL, description TEXT NOT NULL, date TEXT NOT NULL, note TEXT NOT NULL DEFAULT "")',
          );
          await db.execute(
            'CREATE TABLE budgets (id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT NOT NULL, amount REAL NOT NULL CHECK(amount > 0), start_date TEXT NOT NULL, end_date TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE savings_goals (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, target_amount REAL NOT NULL CHECK(target_amount > 0), saved_amount REAL NOT NULL DEFAULT 0, target_date TEXT NOT NULL, description TEXT NOT NULL DEFAULT "")',
          );
          await db.execute(
            'CREATE TABLE profile (id INTEGER PRIMARY KEY CHECK(id = 1), name TEXT NOT NULL, currency TEXT NOT NULL, monthly_income REAL NOT NULL, monthly_budget REAL NOT NULL)',
          );
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
        },
      ),
    );
    database = AppDatabase(database: memoryDb);
    provider = BudgetProvider(database);
    await provider.load();
  });

  tearDown(() => database.close());

  test('income and expense update balance and totals', () async {
    await provider.addOrUpdateTransaction(
      _entry(TransactionType.income, 1000, 'Salary'),
    );
    await provider.addOrUpdateTransaction(
      _entry(TransactionType.expense, 300, 'Food'),
    );
    expect(provider.totalIncome, 1000);
    expect(provider.totalExpenses, 300);
    expect(provider.balance, 700);
  });

  test('editing a transaction recalculates totals', () async {
    await provider.addOrUpdateTransaction(
      _entry(TransactionType.expense, 25, 'Food'),
    );
    final original = provider.transactions.single;
    await provider.addOrUpdateTransaction(
      _entry(TransactionType.expense, 40, 'Food', id: original.id),
    );
    expect(provider.totalExpenses, 40);
    expect(provider.transactions, hasLength(1));
  });

  test('deleting a transaction recalculates balance', () async {
    await provider.addOrUpdateTransaction(
      _entry(TransactionType.income, 100, 'Salary'),
    );
    await provider.removeTransaction(provider.transactions.single.id!);
    expect(provider.balance, 0);
    expect(provider.transactions, isEmpty);
  });

  test('budget calculation uses category and date window', () async {
    final now = DateTime.now();
    await provider.addOrUpdateBudget(
      Budget(
        category: 'Food',
        amount: 200,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
      ),
    );
    await provider.addOrUpdateTransaction(
      _entry(TransactionType.expense, 145, 'Food'),
    );
    await provider.addOrUpdateTransaction(
      _entry(TransactionType.expense, 20, 'Transport'),
    );
    expect(provider.spentFor(provider.budgets.single), 145);
  });

  test('savings progress and transaction searching/filtering work', () async {
    await provider.addOrUpdateGoal(
      SavingsGoal(
        name: 'Laptop',
        targetAmount: 1000,
        savedAmount: 650,
        targetDate: DateTime.now(),
      ),
    );
    await provider.addOrUpdateTransaction(
      _entry(TransactionType.expense, 12, 'Food', description: 'Lunch'),
    );
    await provider.addOrUpdateTransaction(
      _entry(TransactionType.income, 90, 'Salary', description: 'Part time'),
    );
    expect(
      provider.goals.single.savedAmount / provider.goals.single.targetAmount,
      .65,
    );
    expect(provider.filtered(query: 'lunch'), hasLength(1));
    expect(provider.filtered(type: TransactionType.income), hasLength(1));
    expect(provider.filtered(category: 'Missing'), isEmpty);
  });

  test(
    're-importing the same transaction does not create a duplicate',
    () async {
      final entry = _entry(
        TransactionType.expense,
        18,
        'Food',
        description: 'Lunch',
      );
      await provider.importItems([entry]);
      await provider.importItems([entry]);
      expect(provider.transactions, hasLength(1));
    },
  );
}

MoneyTransaction _entry(
  TransactionType type,
  double amount,
  String category, {
  int? id,
  String description = 'Test entry',
}) => MoneyTransaction(
  id: id,
  type: type,
  amount: amount,
  category: category,
  description: description,
  date: DateTime.now(),
);
