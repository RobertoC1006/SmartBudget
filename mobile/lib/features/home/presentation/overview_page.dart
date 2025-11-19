import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/models/alert.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/smart_score.dart';
import '../../../widgets/async_value_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../expenses/controllers/expenses_controller.dart';
import '../controllers/budget_controller.dart';
import '../providers.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final budgetValue = ref.watch(budgetControllerProvider);
    final smartScoreValue = ref.watch(smartScoreProvider);
    final alertsValue = ref.watch(alertsProvider);
    final expensesValue = ref.watch(expensesControllerProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(budgetControllerProvider.notifier).refresh();
        await ref.read(expensesControllerProvider.notifier).load();
        ref.invalidate(alertsProvider);
        await ref.read(alertsProvider.future);
        ref.invalidate(smartScoreProvider);
        await ref.read(smartScoreProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Hola, ${user?.fullName.split(' ').first ?? 'SmartSaver'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Este es tu resumen del mes.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SBColors.muted),
          ),
          const SizedBox(height: 20),
          AsyncValueWidget(
            value: budgetValue,
            onRetry: () => ref.read(budgetControllerProvider.notifier).refresh(),
            builder: (budget) {
              if (budget == null) {
                return _EmptyCard(
                  title: 'Define tu presupuesto',
                  subtitle: 'Crea tu presupuesto mensual y habilita alertas inteligentes.',
                );
              }
              final progress = budget.amount == 0 ? 0.0 : (budget.spent / budget.amount).clamp(0, 1).toDouble();
              final remainingRatio =
                  budget.amount == 0 ? 0.0 : (budget.remaining / budget.amount).clamp(-10, 10).toDouble();
              final isOverspent = budget.remaining < 0;
              final remainingDescription = budget.amount == 0
                  ? 'Sin presupuesto base'
                  : isOverspent
                      ? 'Te excediste ${(remainingRatio.abs() * 100).toStringAsFixed(0)}% del presupuesto'
                      : 'Te queda ${(remainingRatio * 100).toStringAsFixed(0)}% del presupuesto';
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
                      Row(
                        children: [
                          Expanded(
                            child: _BudgetStatCard(
                              title: 'Presupuesto definido',
                              value: Formatters.currency(budget.amount, currency: budget.currency),
                              description: 'Período ${budget.month}/${budget.year}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BudgetStatCard(
                              title: 'Saldo disponible',
                              value: Formatters.currency(budget.remaining, currency: budget.currency),
                              description: remainingDescription,
                              highlight: true,
                              accentColor: isOverspent ? Colors.red : SBColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: SBColors.secondary.withValues(alpha: 0.3),
                        color: SBColors.primary,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Has gastado ${Formatters.currency(budget.spent, currency: budget.currency)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AsyncValueWidget(
                  value: smartScoreValue,
                  onRetry: () => ref.refresh(smartScoreProvider.future),
                  builder: (SmartScoreSnapshot? snapshot) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SmartScore'),
                            const SizedBox(height: 8),
                            Text(
                              snapshot != null ? '${snapshot.score}/100' : '-',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: SBColors.primary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              snapshot?.summary ?? 'Genera tu SmartScore desde la web o el backend.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AsyncValueWidget(
                  value: alertsValue,
                  onRetry: () => ref.refresh(alertsProvider.future),
                  builder: (List<AlertMessage> alerts) {
                    final alert = alerts.isNotEmpty ? alerts.first : null;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Alertas'),
                            const SizedBox(height: 8),
                            if (alert != null) ...[
                              Text(
                                alert.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: _alertColor(alert.severity),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alert.message,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ] else
                              Text(
                                'Sin alertas activas.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Gastos recientes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AsyncValueWidget(
            value: expensesValue,
            onRetry: () => ref.read(expensesControllerProvider.notifier).load(),
            builder: (List<Expense> expenses) {
              if (expenses.isEmpty) {
                return _EmptyCard(
                  title: 'Aún no tienes gastos',
                  subtitle: 'Registra tus consumos desde la pestaña Gastos.',
                );
              }
              final recent = expenses.take(5);
              return Column(
                children: recent
                    .map(
                      (expense) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${expense.category.label} · ${Formatters.shortDate(expense.expenseDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
                        ),
                        trailing: Text(
                          Formatters.currency(expense.amount, currency: expense.currency),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SBColors.dark),
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

  Color _alertColor(AlertSeverity severity) => switch (severity) {
        AlertSeverity.critical => Colors.red,
        AlertSeverity.warning => Colors.orange,
        AlertSeverity.info => SBColors.primary,
      };
}

class _BudgetStatCard extends StatelessWidget {
  const _BudgetStatCard({
    required this.title,
    required this.value,
    required this.description,
    this.highlight = false,
    this.accentColor,
  });

  final String title;
  final String value;
  final String description;
  final bool highlight;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? (accentColor ?? SBColors.primary).withValues(alpha: 0.12)
            : SBColors.light,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? (accentColor ?? SBColors.primary).withValues(alpha: 0.35)
              : SBColors.light,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              color: highlight ? (accentColor ?? SBColors.dark) : SBColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlight ? (accentColor ?? SBColors.dark) : SBColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: textTheme.bodySmall?.copyWith(
              color: highlight
                  ? (accentColor ?? SBColors.dark).withValues(alpha: 0.7)
                  : SBColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
