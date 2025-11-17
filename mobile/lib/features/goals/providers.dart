import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/goal_repository.dart';

final goalSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.suggestions();
});
