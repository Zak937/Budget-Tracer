import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/models.dart';
import '../providers/budget_provider.dart';
import '../widgets/app_widgets.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            onPressed: () => showBudgetEditor(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: state.budgets.isEmpty
          ? const EmptyState(
              icon: Icons.pie_chart_outline,
              message:
                  'No budgets created yet. Create one to stay on top of your spending.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                ...state.budgets.map((budget) => _BudgetCard(budget: budget)),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const GoalsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.savings_outlined),
                  label: const Text('Manage savings goals'),
                ),
              ],
            ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});
  final Budget budget;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    final spent = state.spentFor(budget);
    final ratio = spent / budget.amount;
    final color = ratio >= 1
        ? Colors.red
        : ratio >= .8
        ? Colors.orange
        : brandGreen;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showBudgetEditor(context, budget: budget),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(child: Icon(categoryIcon(budget.category))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${formatDate(budget.startDate)} – ${formatDate(budget.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await showBudgetEditor(context, budget: budget);
                        return;
                      }
                      final confirmed = await confirmAction(
                        context,
                        'Delete budget?',
                        'This budget will be removed.',
                      );
                      if (confirmed && budget.id != null)
                        await state.removeBudget(budget.id!);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Spent ${formatMoney(state, spent)}'),
                  Text(
                    '${(ratio * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 9,
                borderRadius: BorderRadius.circular(9),
                color: color,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget ${formatMoney(state, budget.amount)}'),
                  Text(
                    'Remaining ${formatMoney(state, budget.amount - spent)}',
                  ),
                ],
              ),
              if (ratio >= .8)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      ratio >= 1 ? 'Budget exceeded' : 'Approaching your limit',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showBudgetEditor(BuildContext context, {Budget? budget}) async {
  final state = context.read<BudgetProvider>();
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController(text: budget?.amount.toString() ?? '');
  var category = budget?.category ?? expenseCategories.first;
  var start =
      budget?.startDate ?? DateTime(DateTime.now().year, DateTime.now().month);
  var end =
      budget?.endDate ??
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, refresh) => AlertDialog(
        title: Text(budget == null ? 'Create budget' : 'Edit budget'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: expenseCategories
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    refresh(() => category = value ?? category),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Budget amount (${state.profile.currency})',
                ),
                validator: (value) =>
                    value != null && validPositiveAmount(value)
                    ? null
                    : 'Enter an amount above zero',
              ),
              TextButton.icon(
                onPressed: () async {
                  final selected = await showDateRangePicker(
                    context: dialogContext,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDateRange: DateTimeRange(start: start, end: end),
                  );
                  if (selected != null)
                    refresh(() {
                      start = selected.start;
                      end = selected.end;
                    });
                },
                icon: const Icon(Icons.date_range),
                label: Text('${formatDate(start)} – ${formatDate(end)}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await state.addOrUpdateBudget(
                Budget(
                  id: budget?.id,
                  category: category,
                  amount: double.parse(amount.text),
                  startDate: start,
                  endDate: end,
                ),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  amount.dispose();
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings goals'),
        actions: [
          IconButton(
            onPressed: () => showGoalEditor(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: state.goals.isEmpty
          ? const EmptyState(
              icon: Icons.flag_outlined,
              message: 'Create your first savings goal.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: state.goals
                  .map((goal) => SavingsGoalCard(goal: goal, editable: true))
                  .toList(),
            ),
    );
  }
}

class SavingsGoalCard extends StatelessWidget {
  const SavingsGoalCard({super.key, required this.goal, this.editable = false});
  final SavingsGoal goal;
  final bool editable;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    final progress = goal.savedAmount / goal.targetAmount;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.flag_outlined)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Target ${formatDate(goal.targetDate)} · ${formatMoney(state, goal.targetAmount)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (editable)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'add') {
                        await addSavings(context, goal);
                        return;
                      }
                      if (value == 'edit') {
                        await showGoalEditor(context, goal: goal);
                        return;
                      }
                      final confirmed = await confirmAction(
                        context,
                        'Delete goal?',
                        'This savings goal will be removed.',
                      );
                      if (confirmed && goal.id != null)
                        await state.removeGoal(goal.id!);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'add', child: Text('Add savings')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 9,
              borderRadius: BorderRadius.circular(9),
              color: progress >= 1 ? brandGreen : Colors.deepPurple,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saved ${formatMoney(state, goal.savedAmount)}'),
                Text(
                  progress >= 1
                      ? 'Goal reached!'
                      : '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}% · Left ${formatMoney(state, (goal.targetAmount - goal.savedAmount).clamp(0, double.infinity))}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showGoalEditor(BuildContext context, {SavingsGoal? goal}) async {
  final state = context.read<BudgetProvider>();
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: goal?.name ?? '');
  final target = TextEditingController(
    text: goal?.targetAmount.toString() ?? '',
  );
  final saved = TextEditingController(
    text: goal?.savedAmount.toString() ?? '0',
  );
  final description = TextEditingController(text: goal?.description ?? '');
  var targetDate =
      goal?.targetDate ?? DateTime.now().add(const Duration(days: 180));
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, refresh) => AlertDialog(
        title: Text(goal == null ? 'New savings goal' : 'Edit goal'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Goal name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a goal name'
                      : null,
                ),
                TextFormField(
                  controller: target,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Target (${state.profile.currency})',
                  ),
                  validator: (value) =>
                      value != null && validPositiveAmount(value)
                      ? null
                      : 'Enter a target above zero',
                ),
                TextFormField(
                  controller: saved,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Already saved'),
                  validator: (value) =>
                      value != null &&
                          double.tryParse(value) != null &&
                          double.parse(value) >= 0
                      ? null
                      : 'Enter a valid amount',
                ),
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: dialogContext,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) refresh(() => targetDate = selected);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Target date: ${formatDate(targetDate)}'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final targetAmount = double.parse(target.text);
              final savedAmount = double.parse(saved.text);
              await state.addOrUpdateGoal(
                SavingsGoal(
                  id: goal?.id,
                  name: name.text.trim(),
                  targetAmount: targetAmount,
                  savedAmount: savedAmount,
                  targetDate: targetDate,
                  description: description.text.trim(),
                ),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (goal == null &&
                  savedAmount >= targetAmount &&
                  context.mounted)
                showMessage(context, 'Goal reached! Great work.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  target.dispose();
  saved.dispose();
  description.dispose();
}

Future<void> addSavings(BuildContext context, SavingsGoal goal) async {
  final state = context.read<BudgetProvider>();
  final amount = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Add to ${goal.name}'),
      content: TextField(
        controller: amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Amount to save'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final value = double.tryParse(amount.text);
            if (value == null || value <= 0) {
              showMessage(context, 'Enter an amount greater than zero');
              return;
            }
            final savedAmount = goal.savedAmount + value;
            await state.addOrUpdateGoal(
              SavingsGoal(
                id: goal.id,
                name: goal.name,
                targetAmount: goal.targetAmount,
                savedAmount: savedAmount,
                targetDate: goal.targetDate,
                description: goal.description,
              ),
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            if (savedAmount >= goal.targetAmount && context.mounted)
              showMessage(context, 'Goal reached! Great work.');
          },
          child: const Text('Add savings'),
        ),
      ],
    ),
  );
  amount.dispose();
}
