import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/models.dart';
import '../providers/budget_provider.dart';
import '../widgets/app_widgets.dart';
import 'budget_goal_screens.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String period = 'This month';
  DateTimeRange? customRange;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    final now = DateTime.now();
    final start = switch (period) {
      'This week' => DateTime(now.year, now.month, now.day - now.weekday + 1),
      'Last month' => DateTime(now.year, now.month - 1),
      'Last 3 months' => DateTime(now.year, now.month - 3),
      'This year' => DateTime(now.year),
      'Custom range' => customRange?.start ?? DateTime(now.year, now.month),
      _ => DateTime(now.year, now.month),
    };
    final end = switch (period) {
      'Last month' => DateTime(now.year, now.month, 0, 23, 59, 59),
      'Custom range' => customRange?.end ?? now,
      _ => now,
    };
    final transactions = state.transactions
        .where((item) => !item.date.isBefore(start) && !item.date.isAfter(end))
        .toList();
    final income = transactions
        .where((item) => item.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
    final expenses = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
    final categories = <String, double>{};
    for (final item in transactions.where(
      (item) => item.type == TransactionType.expense,
    )) {
      categories.update(
        item.category,
        (sum) => sum + item.amount,
        ifAbsent: () => item.amount,
      );
    }
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dailyAverage =
        expenses / (end.difference(start).inDays + 1).clamp(1, 100000);
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
        children: [
          DropdownButtonFormField<String>(
            initialValue: period,
            decoration: const InputDecoration(labelText: 'Reporting period'),
            items:
                [
                      'This week',
                      'This month',
                      'Last month',
                      'Last 3 months',
                      'This year',
                      'Custom range',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: _selectPeriod,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Income',
                  value: formatMoney(state, income),
                  icon: Icons.south_west,
                  color: brandGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  title: 'Expenses',
                  value: formatMoney(state, expenses),
                  icon: Icons.north_east,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Net savings',
                  value: formatMoney(state, income - expenses),
                  icon: Icons.savings_outlined,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  title: 'Daily average',
                  value: formatMoney(state, dailyAverage),
                  icon: Icons.today,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Expenses by category',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (sorted.isEmpty)
            const EmptyState(
              icon: Icons.pie_chart_outline,
              message: 'No expense data for this period.',
            )
          else
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 38,
                        sections: sorted
                            .map(
                              (entry) => PieChartSectionData(
                                value: entry.value,
                                title: '',
                                color:
                                    Colors.primaries[sorted.indexOf(entry) %
                                        Colors.primaries.length],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sorted
                          .take(5)
                          .map(
                            (entry) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 5,
                                backgroundColor:
                                    Colors.primaries[sorted.indexOf(entry) %
                                        Colors.primaries.length],
                              ),
                              title: Text(entry.key),
                              trailing: Text(
                                formatMoney(state, entry.value),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Income vs expenses',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                maxY: (income > expenses ? income : expenses) <= 0
                    ? 1
                    : (income > expenses ? income : expenses) * 1.25,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 42),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(value == 0 ? 'Income' : 'Expense'),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: brandGreen,
                        width: 28,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: expenses,
                        color: Colors.deepOrange,
                        width: 28,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Monthly spending',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 190, child: _monthlySpendingChart(state)),
          const SizedBox(height: 16),
          Text(
            'Spending insights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Highest spending category'),
                  trailing: Text(sorted.isEmpty ? '—' : sorted.first.key),
                ),
                ListTile(
                  title: const Text('Lowest spending category'),
                  trailing: Text(sorted.isEmpty ? '—' : sorted.last.key),
                ),
                ListTile(
                  title: const Text('All-time savings'),
                  trailing: Text(formatMoney(state, state.savings)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPeriod(String? value) async {
    if (value == null) return;
    if (value == 'Custom range') {
      final now = DateTime.now();
      final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDateRange: customRange,
      );
      if (selected == null) return;
      setState(() {
        period = value;
        customRange = selected;
      });
      return;
    }
    setState(() => period = value);
  }

  Widget _monthlySpendingChart(BudgetProvider state) {
    final now = DateTime.now();
    final values = List<double>.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index);
      return state.transactions
          .where(
            (item) =>
                item.type == TransactionType.expense &&
                item.date.year == month.year &&
                item.date.month == month.month,
          )
          .fold(0.0, (sum, item) => sum + item.amount);
    });
    final maximum = values.fold(0.0, (a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maximum <= 0 ? 1 : maximum * 1.2,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final month = DateTime(now.year, now.month - 5 + value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM').format(month),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: brandGreen,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.person, size: 44, color: brandGreen),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              state.profile.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Center(child: Text(state.profile.currency)),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Savings goals'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const GoalsScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Financial snapshot',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Total income'),
                  trailing: Text(formatMoney(state, state.totalIncome)),
                ),
                ListTile(
                  title: const Text('Total expenses'),
                  trailing: Text(formatMoney(state, state.totalExpenses)),
                ),
                ListTile(
                  title: const Text('Current balance'),
                  trailing: Text(formatMoney(state, state.balance)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController name;
  late final TextEditingController income;
  late final TextEditingController budget;
  late String currency;
  final formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    final profile = context.read<BudgetProvider>().profile;
    name = TextEditingController(text: profile.name);
    income = TextEditingController(
      text: profile.monthlyIncome == 0 ? '' : profile.monthlyIncome.toString(),
    );
    budget = TextEditingController(
      text: profile.monthlyBudget == 0 ? '' : profile.monthlyBudget.toString(),
    );
    currency = profile.currency;
  }

  @override
  void dispose() {
    name.dispose();
    income.dispose();
    budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your name'
                : null,
          ),
          const SizedBox(height: 12),
          currencyField(currency, (value) => setState(() => currency = value)),
          const SizedBox(height: 12),
          amountField(income, 'Monthly income (optional)', optional: true),
          const SizedBox(height: 12),
          amountField(
            budget,
            'Monthly spending limit (optional)',
            optional: true,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await context.read<BudgetProvider>().updateProfile(
                UserProfile(
                  name: name.text.trim(),
                  currency: currency,
                  monthlyIncome: double.tryParse(income.text) ?? 0,
                  monthlyBudget: double.tryParse(budget.text) ?? 0,
                ),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save profile'),
          ),
        ],
      ),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Appearance'),
                  trailing: DropdownButton<ThemeMode>(
                    value: state.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) state.updateTheme(value);
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Budget alerts'),
                  subtitle: const Text('Show spending and savings alerts'),
                  value: state.notificationsEnabled,
                  onChanged: state.updateNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Data management',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Export transactions'),
                  subtitle: const Text('Save or share a CSV file'),
                  onTap: () => exportTransactions(context),
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Import transactions'),
                  subtitle: const Text('Import a CSV transaction file'),
                  onTap: () => importTransactions(context),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red,
                  ),
                  title: const Text('Delete all data'),
                  subtitle: const Text(
                    'Remove transactions, budgets, goals and profile',
                  ),
                  onTap: () async {
                    final confirmed = await confirmAction(
                      context,
                      'Delete all data?',
                      'This cannot be undone. All local financial data will be removed.',
                    );
                    if (!confirmed) return;
                    await state.clearData();
                    await state.completeOnboarding();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About BudgetMate'),
              subtitle: Text(
                'Offline-first personal finance tracker · Version 1.0.0',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> exportTransactions(BuildContext context) async {
  try {
    final state = context.read<BudgetProvider>();
    final rows = <List<dynamic>>[
      ['Date', 'Type', 'Category', 'Amount', 'Description', 'Note'],
      ...state.transactions.map(
        (item) => [
          DateFormat('yyyy-MM-dd').format(item.date),
          item.type.name,
          item.category,
          item.amount,
          item.description,
          item.note,
        ],
      ),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/budgetmate_transactions.csv');
    await file.writeAsString(csv);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'BudgetMate transaction export',
      ),
    );
  } catch (_) {
    if (context.mounted) {
      showMessage(context, 'Could not export transactions. Please try again.');
    }
  }
}

Future<void> importTransactions(BuildContext context) async {
  final state = context.read<BudgetProvider>();
  try {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (selection == null) {
      return;
    }
    final bytes =
        selection.files.single.bytes ??
        await File(selection.files.single.path!).readAsBytes();
    final rows = const CsvToListConverter().convert(
      String.fromCharCodes(bytes),
    );
    if (rows.length < 2)
      throw const FormatException('The CSV does not contain transactions.');
    final headers = rows.first
        .map((value) => value.toString().toLowerCase().trim())
        .toList();
    int column(String name, int fallback) {
      final index = headers.indexOf(name);
      return index >= 0 ? index : fallback;
    }

    final items = <MoneyTransaction>[];
    for (final row in rows.skip(1)) {
      try {
        final amountIndex = column('amount', 3);
        final amount = double.parse(row[amountIndex].toString());
        if (amount <= 0) {
          continue;
        }
        final typeIndex = column('type', 1);
        final typeValue = row[typeIndex].toString().toLowerCase().trim();
        if (typeValue != 'income' && typeValue != 'expense') {
          continue;
        }
        final category = row[column('category', 2)].toString().trim();
        final description = row[column('description', 4)].toString().trim();
        final validCategories = typeValue == 'income'
            ? incomeCategories
            : expenseCategories;
        if (!validCategories.contains(category) || description.isEmpty) {
          continue;
        }
        final noteIndex = column('note', 5);
        items.add(
          MoneyTransaction(
            type: typeValue == 'income'
                ? TransactionType.income
                : TransactionType.expense,
            amount: amount,
            category: category,
            description: description,
            date: DateTime.parse(row[column('date', 0)].toString()),
            note: noteIndex < row.length ? row[noteIndex].toString() : '',
          ),
        );
      } catch (_) {
        continue;
      }
    }
    if (items.isEmpty) {
      throw const FormatException('No valid transaction rows found.');
    }
    await state.importItems(items);
    if (context.mounted) {
      showMessage(context, 'Imported ${items.length} transactions');
    }
  } catch (_) {
    if (context.mounted) {
      showMessage(
        context,
        'Could not import this CSV. Check its headers and data.',
      );
    }
  }
}

void showAlerts(BuildContext context) {
  final state = context.read<BudgetProvider>();
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial alerts',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (state.alerts.isEmpty)
              const ListTile(
                leading: Icon(Icons.check_circle_outline, color: brandGreen),
                title: Text('You’re all caught up!'),
                subtitle: Text('No budget or savings alerts right now.'),
              )
            else
              ...state.alerts.map(
                (alert) => ListTile(
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(alert),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
