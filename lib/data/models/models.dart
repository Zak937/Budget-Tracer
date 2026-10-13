enum TransactionType { income, expense }

class MoneyTransaction {
  const MoneyTransaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.note = '',
  });
  final int? id;
  final TransactionType type;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String note;

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'category': category,
    'description': description,
    'date': date.toIso8601String(),
    'note': note,
  };
  factory MoneyTransaction.fromMap(Map<String, Object?> map) =>
      MoneyTransaction(
        id: map['id'] as int?,
        type: TransactionType.values.byName(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        description: map['description'] as String,
        date: DateTime.parse(map['date'] as String),
        note: (map['note'] as String?) ?? '',
      );
}

class Budget {
  const Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
  });
  final int? id;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  Map<String, Object?> toMap() => {
    'id': id,
    'category': category,
    'amount': amount,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
  };
  factory Budget.fromMap(Map<String, Object?> map) => Budget(
    id: map['id'] as int?,
    category: map['category'] as String,
    amount: (map['amount'] as num).toDouble(),
    startDate: DateTime.parse(map['start_date'] as String),
    endDate: DateTime.parse(map['end_date'] as String),
  );
}

class SavingsGoal {
  const SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    this.description = '',
  });
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final String description;
  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'target_amount': targetAmount,
    'saved_amount': savedAmount,
    'target_date': targetDate.toIso8601String(),
    'description': description,
  };
  factory SavingsGoal.fromMap(Map<String, Object?> map) => SavingsGoal(
    id: map['id'] as int?,
    name: map['name'] as String,
    targetAmount: (map['target_amount'] as num).toDouble(),
    savedAmount: (map['saved_amount'] as num).toDouble(),
    targetDate: DateTime.parse(map['target_date'] as String),
    description: (map['description'] as String?) ?? '',
  );
}

class UserProfile {
  const UserProfile({
    this.name = '',
    this.currency = 'USD',
    this.monthlyIncome = 0,
    this.monthlyBudget = 0,
  });
  final String name;
  final String currency;
  final double monthlyIncome;
  final double monthlyBudget;
  Map<String, Object?> toMap() => {
    'id': 1,
    'name': name,
    'currency': currency,
    'monthly_income': monthlyIncome,
    'monthly_budget': monthlyBudget,
  };
  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
    name: (map['name'] as String?) ?? '',
    currency: (map['currency'] as String?) ?? 'USD',
    monthlyIncome: ((map['monthly_income'] as num?) ?? 0).toDouble(),
    monthlyBudget: ((map['monthly_budget'] as num?) ?? 0).toDouble(),
  );
}
