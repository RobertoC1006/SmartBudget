enum ExpenseCategory {
  general('general', 'General'),
  vivienda('vivienda', 'Vivienda'),
  alimentacion('alimentacion', 'Alimentación'),
  transporte('transporte', 'Transporte'),
  servicios('servicios', 'Servicios'),
  salud('salud', 'Salud'),
  educacion('educacion', 'Educación'),
  ocio('ocio', 'Ocio'),
  ropa('ropa', 'Ropa'),
  otros('otros', 'Otros');

  const ExpenseCategory(this.value, this.label);
  final String value;
  final String label;

  static ExpenseCategory fromValue(String? value) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => ExpenseCategory.general,
    );
  }
}

enum ExpenseSource { manual, ocr, adjustment }

class Expense {
  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.currency,
    required this.source,
    this.ocrConfidence,
  });

  final String id;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime expenseDate;
  final String currency;
  final ExpenseSource source;
  final double? ocrConfidence;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategory.fromValue(json['category'] as String?),
      expenseDate: DateTime.parse(json['expense_date'] as String),
      currency: (json['currency'] as String?) ?? 'PEN',
      source: ExpenseSource.values.firstWhere(
        (s) => s.name == (json['source'] as String?)?.toLowerCase(),
        orElse: () => ExpenseSource.manual,
      ),
      ocrConfidence: (json['ocr_confidence'] as num?)?.toDouble(),
    );
  }
}

class ExpenseDraft {
  ExpenseDraft({
    required this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.source,
    this.extraData,
    this.ocrConfidence,
  });

  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime expenseDate;
  final ExpenseSource source;
  final Map<String, dynamic>? extraData;
  final double? ocrConfidence;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'category': category.value,
      'expense_date': expenseDate.toIso8601String().substring(0, 10),
      'source': source.name,
      if (extraData != null) 'extra_data': extraData,
      if (ocrConfidence != null) 'ocr_confidence': ocrConfidence,
    };
  }
}
