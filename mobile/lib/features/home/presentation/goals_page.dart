import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/models/goal.dart';
import '../../../widgets/async_value_widget.dart';
import '../../goals/controllers/goals_controller.dart';
import '../../goals/providers.dart';

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
                children: goals
                    .map(
                      (goal) => Card(
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
                                  Chip(
                                    label: Text(_statusLabel(goal.status)),
                                    backgroundColor: _statusColor(goal.status).withValues(alpha: 0.15),
                                    side: BorderSide.none,
                                    labelStyle: TextStyle(color: _statusColor(goal.status)),
                                  ),
                                ],
                              ),
                              if (goal.description != null) ...[
                                const SizedBox(height: 4),
                                Text(goal.description!, style: Theme.of(context).textTheme.bodySmall),
                              ],
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: goal.progress,
                                backgroundColor: SBColors.secondary.withValues(alpha: 0.3),
                                color: SBColors.primary,
                                minHeight: 10,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${Formatters.currency(goal.currentAmount)} / ${Formatters.currency(goal.targetAmount)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
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
                                  onPressed: () => _updateProgress(goal),
                                  child: const Text('Actualizar progreso'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
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

  void _updateProgress(Goal goal) async {
    final controller = TextEditingController(text: goal.currentAmount.toStringAsFixed(2));
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar "${goal.name}"'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto actual',
          ),
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
    if (amount == null) return;
    try {
      await ref.read(goalsControllerProvider.notifier).updateProgress(goal.id, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progreso actualizado')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  String _statusLabel(GoalStatus status) => switch (status) {
        GoalStatus.achieved => 'Completada',
        GoalStatus.inProgress => 'En progreso',
        GoalStatus.missed => 'Perdida',
        GoalStatus.pending => 'Pendiente',
      };

  Color _statusColor(GoalStatus status) => switch (status) {
        GoalStatus.achieved => SBColors.primary,
        GoalStatus.inProgress => Colors.orange,
        GoalStatus.missed => Colors.red,
        GoalStatus.pending => SBColors.muted,
      };

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
