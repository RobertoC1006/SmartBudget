enum GoalStatus { pending, inProgress, achieved, missed }

class Goal {
  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    this.description,
    this.targetDate,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final GoalStatus status;
  final String? description;
  final DateTime? targetDate;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      status: _statusFromString(json['status'] as String?),
      description: json['description'] as String?,
      targetDate: (json['target_date'] as String?) != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
    );
  }

  double get progress => targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
}

GoalStatus _statusFromString(String? value) {
  switch (value) {
    case 'in_progress':
      return GoalStatus.inProgress;
    case 'achieved':
      return GoalStatus.achieved;
    case 'missed':
      return GoalStatus.missed;
    default:
      return GoalStatus.pending;
  }
}
