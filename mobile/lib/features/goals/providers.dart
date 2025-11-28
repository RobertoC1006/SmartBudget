import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/goal_repository.dart';

const _curatedGoalIdeas = [
  'Viaje a Colan',
  'Escapada con amigos',
  'Comprar ropa para la temporada',
  'Renovar laptop o tablet',
  'Fondo de emergencia (3 meses)',
  'Curso o certificacion nueva',
  'Concierto o festival pendiente',
  'Mejorar la habitacion o sala',
];

final goalSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(goalRepositoryProvider);
  final suggestions = <String>[..._curatedGoalIdeas];
  try {
    final remote = await repository.suggestions();
    for (final idea in remote) {
      if (!suggestions.contains(idea)) {
        suggestions.add(idea);
      }
    }
  } catch (_) {
    // Ignora errores y usa solo las ideas curadas para que siempre haya sugerencias
  }
  return suggestions;
});
