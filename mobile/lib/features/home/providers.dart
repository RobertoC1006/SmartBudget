import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/alert.dart';
import '../../data/models/smart_score.dart';
import '../../data/repositories/alert_repository.dart';
import '../../data/repositories/smartscore_repository.dart';

final alertsProvider = FutureProvider<List<AlertMessage>>((ref) async {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.fetchAlerts();
});

final smartScoreProvider = FutureProvider<SmartScoreSnapshot?>((ref) async {
  final repository = ref.watch(smartScoreRepositoryProvider);
  final history = await repository.history();
  return history.isNotEmpty ? history.first : null;
});
