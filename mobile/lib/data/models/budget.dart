class Budget {
  Budget({
    required this.id,
    required this.name,
    required this.month,
    required this.year,
    required this.amount,
    required this.currency,
    required this.spent,
    required this.remaining,
    required this.alertThreshold,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int month;
  final int year;
  final double amount;
  final String currency;
  final double spent;
  final double remaining;
  final double alertThreshold;
  final DateTime updatedAt;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Presupuesto',
      month: json['month'] as int,
      year: json['year'] as int,
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'PEN',
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      alertThreshold: (json['alert_threshold'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
