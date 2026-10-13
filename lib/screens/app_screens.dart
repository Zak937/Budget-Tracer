import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/models.dart';
import '../providers/budget_provider.dart';
import '../widgets/app_widgets.dart';
import 'analytics_settings_screens.dart';
import 'budget_goal_screens.dart';
import 'transaction_screens.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});
  @override
  Widget build(BuildContext context) => Consumer<BudgetProvider>(
    builder: (context, state, _) {
      if (state.loading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (state.error != null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(state.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: state.load,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (!state.onboardingCompleted) return const OnboardingScreen();
      if (state.profile.name.trim().isEmpty) return const ProfileSetupScreen();
      return const MainShell();
    },
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;
  static const slides = [
    (
      Icons.account_balance_wallet_outlined,
      'Track your money',
      'Record income and everyday expenses in one simple place.',
    ),
    (
      Icons.pie_chart_outline,
      'Control your spending',
      'Set category budgets and understand where your money goes.',
    ),
    (
      Icons.flag_outlined,
      'Reach your goals',
      'Build savings habits and celebrate every milestone.',
    ),
  ];
  Future<void> complete() =>
      context.read<BudgetProvider>().completeOnboarding();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: complete, child: const Text('Skip')),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: slides.length,
              onPageChanged: (value) => setState(() => index = value),
              itemBuilder: (context, page) => Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 92,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(slides[page].$1, size: 82, color: brandGreen),
                    ),
                    const SizedBox(height: 38),
                    Text(
                      slides[page].$2,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slides[page].$3,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(4),
                width: i == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == index ? brandGreen : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (index == slides.length - 1) {
                    complete();
                  } else {
                    controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Text(
                  index == slides.length - 1 ? 'Get started' : 'Next',
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final income = TextEditingController();
  final limit = TextEditingController();
  String currency = 'USD';
  @override
  void dispose() {
    name.dispose();
    income.dispose();
    limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set up your profile')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Icon(Icons.waving_hand_outlined, size: 52, color: brandGreen),
          const SizedBox(height: 12),
          Text(
            'Welcome to BudgetMate',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text('A few details help personalize your budget.'),
          const SizedBox(height: 24),
          TextFormField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
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
            limit,
            'Monthly spending limit (optional)',
            optional: true,
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await context.read<BudgetProvider>().updateProfile(
                UserProfile(
                  name: name.text.trim(),
                  currency: currency,
                  monthlyIncome: double.tryParse(income.text) ?? 0,
                  monthlyBudget: double.tryParse(limit.text) ?? 0,
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigate: (index) => setState(() => selected = index)),
      const TransactionsScreen(),
      const BudgetsScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: selected, children: screens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTransactionEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (value) => setState(() => selected = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    final categories = state.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final firstName = state.profile.name.split(' ').first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BudgetMate'),
        actions: [
          IconButton(
            onPressed: () => showAlerts(context),
            icon: Badge(
              isLabelVisible:
                  state.notificationsEnabled && state.alerts.isNotEmpty,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 105),
          children: [
            Text(
              'Good ${DateTime.now().hour < 12 ? 'morning' : 'day'}, $firstName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [brandGreen, brandGreen.withValues(alpha: .78)],
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL BALANCE',
                    style: TextStyle(color: Colors.white70, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatMoney(state, state.balance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _heroMetric(
                          'Income',
                          state,
                          state.totalIncome,
                          Icons.south_west,
                        ),
                      ),
                      Expanded(
                        child: _heroMetric(
                          'Expenses',
                          state,
                          state.totalExpenses,
                          Icons.north_east,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Budget left',
                    value: formatMoney(state, state.remainingMonthlyBudget),
                    icon: Icons.account_balance_wallet_outlined,
                    color: state.remainingMonthlyBudget < 0
                        ? Colors.red
                        : brandGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    title: 'Savings',
                    value: formatMoney(state, state.savings),
                    icon: Icons.savings_outlined,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            if (state.profile.monthlyBudget > 0)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _budgetProgress(context, state),
              ),
            const SizedBox(height: 18),
            _sectionHeading(
              context,
              'Spending breakdown',
              'Reports',
              () => onNavigate(3),
            ),
            if (categories.isEmpty)
              const EmptyState(
                icon: Icons.pie_chart_outline,
                message:
                    'Your category chart will appear after your first expense.',
              )
            else
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 38,
                          sections: categories
                              .take(5)
                              .map(
                                (entry) => PieChartSectionData(
                                  value: entry.value,
                                  title: '',
                                  radius: 25,
                                  color:
                                      Colors.primaries[categories.indexOf(
                                            entry,
                                          ) %
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
                        children: categories
                            .take(4)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 5,
                                      backgroundColor:
                                          Colors.primaries[categories.indexOf(
                                                entry,
                                              ) %
                                              Colors.primaries.length],
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      formatMoney(state, entry.value),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
            _sectionHeading(
              context,
              'Recent activity',
              'See all',
              () => onNavigate(1),
            ),
            if (state.transactions.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                message:
                    'No transactions yet. Start tracking your money by adding your first income or expense.',
              )
            else
              ...state.transactions
                  .take(4)
                  .map(
                    (transaction) => TransactionTile(
                      transaction: transaction,
                      onTap: () => showTransactionEditor(
                        context,
                        transaction: transaction,
                        details: true,
                      ),
                    ),
                  ),
            if (state.goals.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionHeading(
                context,
                'Savings goals',
                'Manage',
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const GoalsScreen()),
                ),
              ),
              ...state.goals.take(2).map((goal) => SavingsGoalCard(goal: goal)),
            ],
            if (state.notificationsEnabled && state.alerts.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(state.alerts.first),
                  onTap: () => showAlerts(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heroMetric(
    String title,
    BudgetProvider state,
    double amount,
    IconData icon,
  ) => Row(
    children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(width: 7),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(
            formatMoney(state, amount),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _sectionHeading(
    BuildContext context,
    String title,
    String action,
    VoidCallback onTap,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );

  Widget _budgetProgress(BuildContext context, BudgetProvider state) {
    final ratio = state.currentMonthExpenses / state.profile.monthlyBudget;
    final color = ratio >= 1
        ? Colors.red
        : ratio >= .8
        ? Colors.orange
        : brandGreen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly spending limit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${(ratio * 100).clamp(0, 999).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 9,
              borderRadius: BorderRadius.circular(8),
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              '${formatMoney(state, state.currentMonthExpenses)} spent of ${formatMoney(state, state.profile.monthlyBudget)}',
            ),
          ],
        ),
      ),
    );
  }
}
