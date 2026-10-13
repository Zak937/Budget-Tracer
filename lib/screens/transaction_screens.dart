import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/models/models.dart';
import '../providers/budget_provider.dart';
import '../widgets/app_widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final search = TextEditingController();
  String? category;
  TransactionType? type;
  DateTimeRange? range;
  bool newestFirst = true;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetProvider>();
    final results = state.filtered(
      query: search.text,
      category: category,
      type: type,
      range: range,
      newestFirst: newestFirst,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => newestFirst = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: Text('Newest first')),
              PopupMenuItem(value: false, child: Text('Oldest first')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search description, category or note',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _showFilters,
                  icon: Icon(
                    Icons.tune,
                    color: category != null || type != null || range != null
                        ? brandGreen
                        : null,
                  ),
                ),
              ),
            ),
          ),
          if (category != null || type != null || range != null)
            Wrap(
              spacing: 4,
              children: [
                if (type != null)
                  InputChip(
                    label: Text(type!.name),
                    onDeleted: () => setState(() => type = null),
                  ),
                if (category != null)
                  InputChip(
                    label: Text(category!),
                    onDeleted: () => setState(() => category = null),
                  ),
                if (range != null)
                  InputChip(
                    label: Text(
                      '${DateFormat.Md().format(range!.start)}–${DateFormat.Md().format(range!.end)}',
                    ),
                    onDeleted: () => setState(() => range = null),
                  ),
                TextButton(
                  onPressed: () => setState(() {
                    type = null;
                    category = null;
                    range = null;
                  }),
                  child: const Text('Clear all'),
                ),
              ],
            ),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    message: 'No transactions match your filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final day = DateUtils.dateOnly(item.date);
                      final previous = index == 0
                          ? null
                          : DateUtils.dateOnly(results[index - 1].date);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (previous == null ||
                              !day.isAtSameMomentAs(previous))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                              child: Text(
                                DateUtils.isSameDay(day, DateTime.now())
                                    ? 'TODAY'
                                    : DateFormat(
                                        'EEEE, MMM d',
                                      ).format(day).toUpperCase(),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          TransactionTile(
                            transaction: item,
                            onTap: () => showTransactionEditor(
                              context,
                              transaction: item,
                              details: true,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, refresh) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter transactions',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TransactionType?>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  const DropdownMenuItem<TransactionType?>(
                    value: null,
                    child: Text('All types'),
                  ),
                  ...TransactionType.values.map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value.name)),
                  ),
                ],
                onChanged: (value) => refresh(() => type = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ...{...expenseCategories, ...incomeCategories}.map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  ),
                ],
                onChanged: (value) => refresh(() => category = value),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final selected = await showDateRangePicker(
                    context: sheetContext,
                    firstDate: DateTime(2000),
                    lastDate: now.add(const Duration(days: 365)),
                    initialDateRange: range,
                  );
                  if (selected != null) refresh(() => range = selected);
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  range == null
                      ? 'Choose date range'
                      : '${formatDate(range!.start)} – ${formatDate(range!.end)}',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}

Future<void> showTransactionEditor(
  BuildContext context, {
  MoneyTransaction? transaction,
  bool details = false,
}) async {
  final state = context.read<BudgetProvider>();
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController(
    text: transaction?.amount.toString() ?? '',
  );
  final description = TextEditingController(
    text: transaction?.description ?? '',
  );
  final note = TextEditingController(text: transaction?.note ?? '');
  var type = transaction?.type ?? TransactionType.expense;
  var category = transaction?.category;
  var date = transaction?.date ?? DateTime.now();

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, refresh) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      details
                          ? 'Transaction details'
                          : transaction == null
                          ? 'Add transaction'
                          : 'Edit transaction',
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.north_east),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.south_west),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: details
                      ? null
                      : (values) => refresh(() {
                          type = values.first;
                          category = null;
                        }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amount,
                  readOnly: details,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (${state.profile.currency})',
                  ),
                  validator: (value) =>
                      value != null && validPositiveAmount(value)
                      ? null
                      : 'Enter an amount greater than zero',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      (type == TransactionType.expense
                              ? expenseCategories
                              : incomeCategories)
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  validator: (value) =>
                      value == null ? 'Choose a category' : null,
                  onChanged: details
                      ? null
                      : (value) => refresh(() => category = value),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: description,
                  readOnly: details,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Add a description'
                      : null,
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: details
                      ? null
                      : () async {
                          final selected = await showDatePicker(
                            context: sheetContext,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (selected != null) refresh(() => date = selected);
                        },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(formatDate(date)),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: note,
                  readOnly: details,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                if (details)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            showTransactionEditor(
                              context,
                              transaction: transaction,
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final confirmed = await confirmAction(
                              context,
                              'Delete transaction?',
                              'This transaction will be permanently removed.',
                            );
                            if (!confirmed || transaction?.id == null) return;
                            await state.removeTransaction(transaction!.id!);
                            if (sheetContext.mounted)
                              Navigator.pop(sheetContext);
                            if (context.mounted)
                              showMessage(context, 'Transaction deleted');
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final savedType = type;
                        await state.addOrUpdateTransaction(
                          MoneyTransaction(
                            id: transaction?.id,
                            type: type,
                            amount: double.parse(amount.text),
                            category: category!,
                            description: description.text.trim(),
                            date: date,
                            note: note.text.trim(),
                          ),
                        );
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (context.mounted)
                          showMessage(context, '${savedType.name} saved');
                      },
                      child: Text(
                        transaction == null
                            ? 'Save ${type.name}'
                            : 'Save changes',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  amount.dispose();
  description.dispose();
  note.dispose();
}
