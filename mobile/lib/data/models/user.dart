class User {
  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.defaultCurrency,
    required this.isActive,
    required this.createdAt,
    this.monthlyIncome,
  });

  final String id;
  final String fullName;
  final String email;
  final String defaultCurrency;
  final bool isActive;
  final DateTime createdAt;
  final double? monthlyIncome;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      defaultCurrency: (json['default_currency'] as String?) ?? 'PEN',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble(),
    );
  }
}
