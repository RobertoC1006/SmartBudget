enum AlertSeverity { info, warning, critical }

class AlertMessage {
  AlertMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime createdAt;

  factory AlertMessage.fromJson(Map<String, dynamic> json) {
    final severityValue = (json['severity'] as String?) ?? 'info';
    return AlertMessage(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: AlertSeverity.values.firstWhere(
        (s) => s.name == severityValue,
        orElse: () => AlertSeverity.info,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
