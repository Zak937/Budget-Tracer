import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/models/models.dart';
import '../providers/budget_provider.dart';

const brandGreen = Color(0xFF168C72);
const expenseCategories = [
  'Food',
  'Transport',
  'Education',
  'Shopping',
  'Bills',
  'Entertainment',
  'Health',
  'Rent',
  'Other',
];
const incomeCategories = [
  'Salary',
  'Allowance',
  'Freelance',
  'Business',
  'Gift',
  'Other',
];
const supportedCurrencies = ['USD', 'SOS', 'EUR', 'GBP', 'KES'];

String formatMoney(BudgetProvider state, double amount) =>
    '${state.profile.currency} ${NumberFormat('#,##0.00').format(amount)}';
String formatDate(DateTime date) => DateFormat('MMM d, y').format(date);

IconData categoryIcon(String category) => switch (category) {
  'Food' => Icons.restaurant,
  'Transport' => Icons.directions_bus,
  'Education' => Icons.school,
  'Shopping' => Icons.shopping_bag_outlined,
  'Bills' => Icons.receipt,
  'Entertainment' => Icons.movie_outlined,
  'Health' => Icons.favorite_outline,
  'Rent' => Icons.home_outlined,
  'Salary' => Icons.work_outline,
  'Allowance' => Icons.card_giftcard,
  _ => Icons.payments_outlined,
};

Widget currencyField(String value, ValueChanged<String> onChanged) =>
    DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Preferred currency'),
      items: supportedCurrencies
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );

Widget amountField(
  TextEditingController controller,
  String label, {
  bool optional = false,
}) => TextFormField(
  controller: controller,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  decoration: InputDecoration(
    labelText: label,
    prefixIcon: const Icon(Icons.payments_outlined),
  ),
  validator: (value) {
    if ((value == null || value.trim().isEmpty) && !optional)
      return 'This field is required';
    if (value != null && value.trim().isNotEmpty) {
      final amount = double.tryParse(value);
      if (amount == null || amount < 0) return 'Enter a valid amount';
    }
    return null;
  },
);

bool validPositiveAmount(String value) {
  final amount = double.tryParse(value.trim());
  return amount != null && amount > 0;
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 34),
    child: Column(
      children: [
        Icon(
          icon,
          size: 48,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .65),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});
  final MoneyTransaction transaction;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    final isIncome = transaction.type == TransactionType.income;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: (isIncome ? brandGreen : Colors.deepOrange)
              .withValues(alpha: .12),
          child: Icon(
            categoryIcon(transaction.category),
            color: isIncome ? brandGreen : Colors.deepOrange,
          ),
        ),
        title: Text(
          transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${transaction.category} · ${DateFormat('MMM d').format(transaction.date)}',
        ),
        trailing: Text(
          '${isIncome ? '+' : '−'}${formatMoney(state, transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? brandGreen : null,
          ),
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}
