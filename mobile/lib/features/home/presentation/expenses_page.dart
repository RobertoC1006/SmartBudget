import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/ocr_scan_result.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../widgets/async_value_widget.dart';
import '../../expenses/controllers/expenses_controller.dart';
import '../../expenses/services/receipt_picker.dart';
import '../../home/controllers/budget_controller.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  final _manualFormKey = GlobalKey<FormState>();
  final _manualDescription = TextEditingController();
  final _manualAmount = TextEditingController();
  ExpenseCategory _manualCategory = ExpenseCategory.general;
  DateTime? _manualDate;
  bool _manualSaving = false;

  final _ocrDescription = TextEditingController();
  final _ocrAmount = TextEditingController();
  ExpenseCategory _ocrCategory = ExpenseCategory.general;
  DateTime? _ocrDate;
  String? _ocrRawText;
  String? _ocrStatus;
  bool _processingOcr = false;
  bool _savingOcr = false;
  OcrScanResult? _scanResult;

  @override
  void dispose() {
    _manualDescription.dispose();
    _manualAmount.dispose();
    _ocrDescription.dispose();
    _ocrAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesValue = ref.watch(expensesControllerProvider);
    final picker = ref.watch(receiptPickerProvider);
    final budgetValue = ref.watch(budgetControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(expensesControllerProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Registra un gasto',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _manualFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _manualDescription,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _manualAmount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requerido';
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ExpenseCategory>(
                      value: _manualCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: ExpenseCategory.values
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.label),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _manualCategory = value ?? _manualCategory),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickDate().then((value) {
                        if (value != null) {
                          setState(() => _manualDate = value);
                        }
                      }),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha (opcional)'),
                        child: Text(
                          _manualDate != null ? DateFormat.yMMMd('es_PE').format(_manualDate!) : 'Hoy',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _manualSaving ? null : _saveManualExpense,
                        icon: _manualSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('Registrar gasto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Escanear recibo con N8N',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _processingOcr ? null : () => _pickReceipt(() => picker.fromCamera()),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Cámara'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _processingOcr ? null : () => _pickReceipt(() => picker.fromGallery()),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _processingOcr ? null : () => _pickReceipt(() => picker.fromFiles()),
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Archivo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_ocrStatus != null)
                    Text(
                      _ocrStatus!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ocrDescription,
                    decoration: const InputDecoration(labelText: 'Descripción OCR'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ocrAmount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto OCR'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseCategory>(
                    value: _ocrCategory,
                    decoration: const InputDecoration(labelText: 'Categoría OCR'),
                    items: ExpenseCategory.values
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.label),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _ocrCategory = value ?? _ocrCategory),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _pickDate().then((value) {
                      if (value != null) setState(() => _ocrDate = value);
                    }),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Fecha OCR'),
                      child: Text(
                        _ocrDate != null ? DateFormat.yMMMd('es_PE').format(_ocrDate!) : 'Detectada automáticamente',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_ocrRawText != null)
                    ExpansionTile(
                      title: const Text('Texto detectado'),
                      children: [
                        Text(
                          _ocrRawText!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_scanResult == null || _savingOcr) ? null : _saveOcrExpense,
                      icon: _savingOcr
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.assignment_turned_in),
                      label: const Text('Guardar desde OCR'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Historial de gastos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildFilters(ref),
          const SizedBox(height: 8),
          AsyncValueWidget(
            value: expensesValue,
            onRetry: () => ref.read(expensesControllerProvider.notifier).load(),
            builder: (List<Expense> expenses) {
              if (expenses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aún no registras gastos.'),
                );
              }
              return Column(
                children: expenses
                    .map(
                      (expense) => Card(
                        child: ListTile(
                          title: Text(expense.description),
                          subtitle: Text(
                            '${expense.category.label} · ${Formatters.date(expense.expenseDate)}',
                          ),
                          trailing: Text(
                            Formatters.currency(expense.amount, currency: expense.currency),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          budgetValue.maybeWhen(
            data: (budget) => budget != null
                ? Text(
                    'Saldo disponible: ${Formatters.currency(budget.remaining, currency: budget.currency)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SBColors.muted),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref) {
    final currentFilter = ref.watch(expensesFilterProvider);
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: currentFilter == null,
          onSelected: (value) {
            if (value) {
              ref.read(expensesControllerProvider.notifier).load(category: null);
            }
          },
        ),
        ...ExpenseCategory.values.map(
          (category) => ChoiceChip(
            label: Text(category.label),
            selected: currentFilter == category,
            onSelected: (value) {
              if (value) {
                ref.read(expensesControllerProvider.notifier).load(category: category);
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveManualExpense() async {
    if (!_manualFormKey.currentState!.validate()) return;
    setState(() => _manualSaving = true);
    try {
      final draft = ExpenseDraft(
        description: _manualDescription.text.trim(),
        amount: double.parse(_manualAmount.text),
        category: _manualCategory,
        expenseDate: _manualDate ?? DateTime.now(),
        source: ExpenseSource.manual,
      );
      await ref.read(expensesControllerProvider.notifier).createExpense(draft);
      await ref.read(budgetControllerProvider.notifier).refresh();
      if (mounted) {
        _manualDescription.clear();
        _manualAmount.clear();
        _manualCategory = ExpenseCategory.general;
        _manualDate = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto registrado')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _manualSaving = false);
    }
  }

  Future<void> _pickReceipt(Future<File?> Function() action) async {
    setState(() {
      _processingOcr = true;
      _ocrStatus = 'Procesando archivo...';
      _scanResult = null;
    });
    try {
      final file = await action();
      if (file == null) {
        setState(() {
          _ocrStatus = 'No se seleccionó archivo.';
          _processingOcr = false;
        });
        return;
      }
      final result = await ref.read(expenseRepositoryProvider).runAutomation(file);
      setState(() {
        _scanResult = result;
        _ocrDescription.text = result.description ?? '';
        _ocrAmount.text = result.amount?.toStringAsFixed(2) ?? '';
        _ocrCategory = ExpenseCategory.fromValue(result.category);
        _ocrDate = result.expenseDate;
        _ocrRawText = result.rawText;
        _ocrStatus = 'La automatización completó los campos. Revisa antes de guardar.';
      });
    } catch (error) {
      setState(() {
        _ocrStatus = error.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingOcr = false);
      }
    }
  }

  Future<void> _saveOcrExpense() async {
    final description = _ocrDescription.text.trim();
    final amount = double.tryParse(_ocrAmount.text);
    if (description.isEmpty || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa descripción y monto detectados.')),
      );
      return;
    }
    setState(() => _savingOcr = true);
    try {
      final draft = ExpenseDraft(
        description: description,
        amount: amount,
        category: _ocrCategory,
        expenseDate: _ocrDate ?? DateTime.now(),
        source: ExpenseSource.ocr,
        extraData: {
          if (_scanResult?.provider != null) 'ocr_provider': _scanResult!.provider,
          if (_ocrRawText != null) 'ocr_raw_text': _ocrRawText,
          if (_scanResult?.payload != null) 'ocr_payload': _scanResult!.payload,
        },
        ocrConfidence: _scanResult?.ocrConfidence,
      );
      await ref.read(expensesControllerProvider.notifier).createExpense(draft);
      await ref.read(budgetControllerProvider.notifier).refresh();
      setState(() {
        _scanResult = null;
        _ocrDescription.clear();
        _ocrAmount.clear();
        _ocrRawText = null;
        _ocrStatus = 'Gasto guardado. Sube otro archivo para continuar.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto desde OCR registrado')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _savingOcr = false);
    }
  }

  Future<DateTime?> _pickDate() async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      locale: const Locale('es', 'PE'),
    );
  }
}
