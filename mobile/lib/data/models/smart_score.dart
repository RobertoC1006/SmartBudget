class SmartScoreSnapshot {
  SmartScoreSnapshot({
    required this.id,
    required this.score,
    required this.band,
    required this.summary,
    required this.createdAt,
    this.drivers,
  });

  final String id;
  final int score;
  final String band;
  final String summary;
  final DateTime createdAt;
  final Map<String, dynamic>? drivers;

  factory SmartScoreSnapshot.fromJson(Map<String, dynamic> json) {
    return SmartScoreSnapshot(
      id: json['id'] as String,
      score: json['score'] as int,
      band: (json['band'] as String?) ?? '',
      summary: json['summary'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      drivers: (json['drivers'] as Map<String, dynamic>?),
    );
  }
}
