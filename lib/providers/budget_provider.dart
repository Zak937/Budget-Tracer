import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import '../data/models/models.dart';

class BudgetProvider extends ChangeNotifier {
  BudgetProvider(this.db);
  final AppDatabase db;
  List<MoneyTransaction> transactions = [];
  List<Budget> budgets = [];
  List<SavingsGoal> goals = [];
  UserProfile profile = const UserProfile();
  ThemeMode themeMode = ThemeMode.system;
  bool notificationsEnabled = true;
  bool onboardingCompleted = false;
  bool loading = true;
  bool _initialized = false;
  String? error;

  Future<void> load() async {
    try {
      loading = !_initialized;
      notifyListeners();
      final result = await Future.wait<Object>([
        db.transactions(),
        db.budgets(),
        db.goals(),
        db.profile(),
        db.setting('theme', 'system'),
        db.setting('notifications_enabled', 'true'),
        db.setting('onboarding_completed', 'false'),
      ]);
      transactions = result[0] as List<MoneyTransaction>;
      budgets = result[1] as List<Budget>;
      goals = result[2] as List<SavingsGoal>;
      profile = result[3] as UserProfile;
      themeMode = switch (result[4] as String) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
      notificationsEnabled = result[5] == 'true';
      onboardingCompleted = result[6] == 'true';
      error = null;
    } catch (_) {
      error = 'Your data could not be loaded. Please restart BudgetMate.';
    }
    _initialized = true;
    loading = false;
    notifyListeners();
  }

  double get totalIncome => _sum(TransactionType.income);
  double get totalExpenses => _sum(TransactionType.expense);
  double _sum(TransactionType type) => transactions
      .where((t) => t.type == type)
      .fold(0, (sum, t) => sum + t.amount);
  double get balance => totalIncome - totalExpenses;
  double get savings => balance;
  double get currentMonthExpenses => transactions
      .where(
        (t) =>
            t.type == TransactionType.expense &&
            t.date.year == DateTime.now().year &&
            t.date.month == DateTime.now().month,
      )
      .fold(0, (sum, t) => sum + t.amount);
  double get remainingMonthlyBudget =>
      profile.monthlyBudget - currentMonthExpenses;
  double spentFor(Budget budget) => transactions
      .where(
        (t) =>
            t.type == TransactionType.expense &&
            t.category == budget.category &&
            !DateUtils.dateOnly(
              t.date,
            ).isBefore(DateUtils.dateOnly(budget.startDate)) &&
            !DateUtils.dateOnly(
              t.date,
            ).isAfter(DateUtils.dateOnly(budget.endDate)),
      )
      .fold(0, (sum, t) => sum + t.amount);
  double spentForCategory(String category) => transactions
      .where(
        (t) =>
            t.type == TransactionType.expense &&
            t.category == category &&
            !t.date.isBefore(
              DateTime(DateTime.now().year, DateTime.now().month),
            ),
      )
      .fold(0, (sum, t) => sum + t.amount);

  Future<void> addOrUpdateTransaction(MoneyTransaction item) async {
    await db.saveTransaction(item);
    await load();
  }

  Future<void> removeTransaction(int id) async {
    await db.deleteTransaction(id);
    await load();
  }

  Future<void> addOrUpdateBudget(Budget item) async {
    await db.saveBudget(item);
    await load();
  }

  Future<void> removeBudget(int id) async {
    await db.deleteBudget(id);
    await load();
  }

  Future<void> addOrUpdateGoal(SavingsGoal item) async {
    await db.saveGoal(item);
    await load();
  }

  Future<void> removeGoal(int id) async {
    await db.deleteGoal(id);
    await load();
  }

  Future<void> updateProfile(UserProfile value) async {
    await db.saveProfile(value);
    await load();
  }

  Future<void> updateTheme(ThemeMode value) async {
    themeMode = value;
    await db.setSetting(
      'theme',
      value == ThemeMode.dark
          ? 'dark'
          : value == ThemeMode.light
          ? 'light'
          : 'system',
    );
    notifyListeners();
  }

  Future<void> updateNotifications(bool value) async {
    notificationsEnabled = value;
    await db.setSetting('notifications_enabled', '$value');
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingCompleted = true;
    await db.setSetting('onboarding_completed', 'true');
    notifyListeners();
  }

  Future<void> importItems(List<MoneyTransaction> items) async {
    await db.importTransactions(items);
    await load();
  }

  Future<void> clearData() async {
    await db.clearAll();
    await load();
  }

  List<MoneyTransaction> filtered({
    String query = '',
    String? category,
    TransactionType? type,
    DateTimeRange? range,
    bool newestFirst = true,
  }) {
    final normalized = query.trim().toLowerCase();
    final result = transactions.where((t) {
      final textMatches =
          normalized.isEmpty ||
          '${t.description} ${t.category} ${t.note}'.toLowerCase().contains(
            normalized,
          );
      return textMatches &&
          (category == null || category == t.category) &&
          (type == null || type == t.type) &&
          (range == null ||
              (!DateUtils.dateOnly(
                    t.date,
                  ).isBefore(DateUtils.dateOnly(range.start)) &&
                  !DateUtils.dateOnly(
                    t.date,
                  ).isAfter(DateUtils.dateOnly(range.end))));
    }).toList();
    result.sort(
      (a, b) =>
          newestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
    );
    return result;
  }

  Map<String, double> get expenseByCategory {
    final result = <String, double>{};
    for (final item in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      result.update(
        item.category,
        (v) => v + item.amount,
        ifAbsent: () => item.amount,
      );
    }
    return result;
  }

  List<String> get alerts {
    final messages = <String>[];
    for (final budget in budgets) {
      final ratio = budget.amount <= 0 ? 0 : spentFor(budget) / budget.amount;
      if (ratio >= 1) {
        messages.add('You have exceeded your ${budget.category} budget.');
      } else if (ratio >= .8) {
        messages.add(
          'Your ${budget.category} budget is ${(ratio * 100).round()}% used.',
        );
      }
    }
    for (final goal in goals) {
      final remaining = goal.targetAmount - goal.savedAmount;
      if (remaining > 0 && remaining <= goal.targetAmount * .1) {
        messages.add(
          'You are ${profile.currency} ${remaining.toStringAsFixed(0)} away from your ${goal.name} goal.',
        );
      }
    }
    return messages;
  }
}
