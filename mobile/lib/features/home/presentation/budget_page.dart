import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/models/budget.dart';
import '../../../widgets/async_value_widget.dart';
import '../controllers/budget_controller.dart';

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController(text: 'Presupuesto mensual');
  final _thresholdController = TextEditingController(text: '0.8');
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetValue = ref.watch(budgetControllerProvider);
    budgetValue.whenData((budget) {
      if (budget != null && _amountController.text.isEmpty) {
        _amountController.text = budget.amount.toStringAsFixed(2);
        _nameController.text = budget.name;
        _thresholdController.text = budget.alertThreshold.toStringAsFixed(2);
        _month = budget.month;
        _year = budget.year;
      }
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(budgetControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Tu presupuesto',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AsyncValueWidget(
            value: budgetValue,
            onRetry: () => ref.read(budgetControllerProvider.notifier).refresh(),
            builder: (Budget? budget) {
              if (budget == null) {
                return const _BudgetSummaryPlaceholder();
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _BudgetSummaryRow(
                        label: 'Período',
                        value: '${budget.month}/${budget.year}',
                      ),
                      _BudgetSummaryRow(
                        label: 'Monto',
                        value: Formatters.currency(budget.amount, currency: budget.currency),
                      ),
                      _BudgetSummaryRow(
                        label: 'Gastado',
                        value: Formatters.currency(budget.spent, currency: budget.currency),
                      ),
                      _BudgetSummaryRow(
                        label: 'Disponible',
                        value: Formatters.currency(budget.remaining, currency: budget.currency),
                        valueColor: SBColors.primary,
                      ),
                      _BudgetSummaryRow(
                        label: 'Umbral alerta',
                        value: '${(budget.alertThreshold * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Actualizar presupuesto',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Form(
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
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa un monto';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _month,
                        items: List.generate(
                          12,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('Mes ${index + 1}'),
                          ),
                        ),
                        onChanged: (value) => setState(() => _month = value ?? _month),
                        decoration: const InputDecoration(labelText: 'Mes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _year,
                        items: List.generate(
                          3,
                          (index) => DropdownMenuItem(
                            value: DateTime.now().year - 1 + index,
                            child: Text('${DateTime.now().year - 1 + index}'),
                          ),
                        ),
                        onChanged: (value) => setState(() => _year = value ?? _year),
                        decoration: const InputDecoration(labelText: 'Año'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _thresholdController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Umbral de alerta (0-1)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed < 0 || parsed > 1) {
                      return 'Debe ser entre 0 y 1';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text);
    final threshold = double.tryParse(_thresholdController.text);
    setState(() {
      _saving = true;
    });
    try {
      await ref.read(budgetControllerProvider.notifier).save(
            amount: amount,
            month: _month,
            year: _year,
            name: _nameController.text.trim(),
            alertThreshold: threshold,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presupuesto actualizado')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _BudgetSummaryRow extends StatelessWidget {
  const _BudgetSummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? SBColors.dark,
                ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSummaryPlaceholder extends StatelessWidget {
  const _BudgetSummaryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sin presupuesto activo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Define un monto mensual para recibir alertas de consumo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
