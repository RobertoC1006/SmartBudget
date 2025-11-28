import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/models/goal.dart';
import '../../../widgets/async_value_widget.dart';
import '../../expenses/controllers/expenses_controller.dart';
import '../../goals/controllers/goals_controller.dart';
import '../../goals/providers.dart';
import '../controllers/budget_controller.dart';
import '../providers.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsValue = ref.watch(goalsControllerProvider);
    final suggestionsValue = ref.watch(goalSuggestionsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(goalsControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Metas de ahorro',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          suggestionsValue.when(
            data: (suggestions) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .take(6)
                  .map(
                    (suggestion) => ActionChip(
                      label: Text(suggestion),
                      onPressed: () {
                        setState(() {
                          _nameController.text = suggestion;
                          _descriptionController.text = suggestion;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
            error: (error, _) => Text(
              'No fue posible cargar sugerencias: $error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Crear meta',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) => value == null || value.isEmpty ? 'Ingresa un nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto objetivo'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa un monto';
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickDate().then((value) {
                        if (value != null) setState(() => _targetDate = value);
                      }),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha objetivo (opcional)'),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _targetDate != null ? DateFormat.yMMMd('es_PE').format(_targetDate!) : 'Selecciona una fecha',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _createGoal,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar meta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Progreso',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AsyncValueWidget(
            value: goalsValue,
            onRetry: () => ref.read(goalsControllerProvider.notifier).refresh(),
            builder: (List<Goal> goals) {
              if (goals.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aún no registras metas.'),
                );
              }
              return Column(
                children: goals.map((goal) => _GoalCard(goal: goal, onUpdate: () => _updateProgress(goal))).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(goalsControllerProvider.notifier).createGoal(
            name: _nameController.text.trim(),
            amount: double.parse(_amountController.text),
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            targetDate: _targetDate,
          );
      if (mounted) {
        _nameController.clear();
        _descriptionController.clear();
        _amountController.clear();
        _targetDate = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta creada')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateProgress(Goal goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar "${goal.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Llevas ${Formatters.currency(goal.currentAmount)} de ${Formatters.currency(goal.targetAmount)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a agregar',
                hintText: 'Ej. 10.50',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(double.tryParse(controller.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un monto mayor a 0 para avanzar la meta.')),
        );
      }
      return;
    }
    try {
      await ref.read(goalsControllerProvider.notifier).updateProgress(goal.id, amount);
      await _refreshBudgetContext();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progreso actualizado')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _refreshBudgetContext() async {
    await ref.read(expensesControllerProvider.notifier).load();
    await ref.read(budgetControllerProvider.notifier).refresh();
    ref.invalidate(alertsProvider);
    await ref.read(alertsProvider.future);
    ref.invalidate(smartScoreProvider);
    await ref.read(smartScoreProvider.future);
  }

  Future<DateTime?> _pickDate() {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      locale: const Locale('es', 'PE'),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onUpdate});

  final Goal goal;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final mood = _progressMood(progress);
    final progressColor = mood.color;
    final barFill = progress.clamp(0, 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (goal.description != null) ...[
              const SizedBox(height: 4),
              Text(goal.description!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mood.highlight ? mood.color.withValues(alpha: 0.08) : SBColors.light,
                borderRadius: BorderRadius.circular(12),
                boxShadow: mood.highlight
                    ? [
                        BoxShadow(
                          color: mood.color.withValues(alpha: 0.15),
                          blurRadius: 14,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: mood.highlight ? mood.color : SBColors.dark,
                            ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: progressColor,
                                ),
                          ),
                          if (mood.badge != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.85, end: 1.05),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeInOut,
                                builder: (context, scale, child) => Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                                child: Chip(
                                  label: Text(
                                    mood.badge!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: mood.color,
                                  side: BorderSide.none,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: SBColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            height: 10,
                            width: constraints.maxWidth * barFill,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  progressColor.withValues(alpha: 0.8),
                                  progressColor.withValues(alpha: 0.95),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${Formatters.currency(goal.currentAmount)} / ${Formatters.currency(goal.targetAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
                      ),
                      if (mood.note != null)
                        Row(
                          children: [
                            Icon(Icons.bolt, size: 14, color: mood.color),
                            const SizedBox(width: 4),
                            Text(
                              mood.note!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: mood.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (goal.targetDate != null)
              Text(
                'Objetivo: ${Formatters.date(goal.targetDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onUpdate,
                child: const Text('Actualizar progreso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


_ProgressMood _progressMood(double progress) {
  if (progress >= 1) {
    return _ProgressMood(
      color: _mix(SBColors.primary, SBColors.light, 0.55),
      badge: 'Meta alcanzada',
      note: null,
      highlight: false,
    );
  } else if (progress >= 0.8) {
    return _ProgressMood(
      color: _mix(SBColors.primary, SBColors.light, 0.35),
      badge: 'Casi llegas',
      note: 'Ultimo empujon para cerrar la meta',
      highlight: true,
    );
  } else if (progress < 0.3) {
    return _ProgressMood(
      color: _mix(SBColors.primary, Colors.white, 0.15),
      badge: 'Arrancaste',
      note: 'Sigue sumando, cada sol cuenta',
      highlight: false,
    );
  } else if (progress < 0.5) {
    return _ProgressMood(
      color: _mix(SBColors.primary, SBColors.secondary, 0.35),
      badge: 'Buen ritmo',
      note: 'Manten el paso',
      highlight: false,
    );
  } else if (progress < 0.7) {
    return _ProgressMood(
      color: _mix(SBColors.primary, SBColors.dark, 0.2),
      badge: 'Mitad de camino',
      note: 'Ya se siente mas cerca',
      highlight: false,
    );
  } else if (progress < 0.8) {
    return _ProgressMood(
      color: _mix(SBColors.primary, Colors.lightGreen, 0.3),
      badge: 'Casi 3/4',
      note: 'Un poco mas y entras al sprint final',
      highlight: false,
    );
  }

  return _ProgressMood(
    color: SBColors.primary,
    badge: null,
    note: null,
    highlight: false,
  );
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;
class _ProgressMood {
  _ProgressMood({
    required this.color,
    this.badge,
    this.note,
    this.highlight = false,
  });

  final Color color;
  final String? badge;
  final String? note;
  final bool highlight;
}
