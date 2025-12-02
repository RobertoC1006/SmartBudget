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
              final overshootPct = isOverspent ? ((budget.spent / budget.amount) * 100 - 100).clamp(0, 999) : 0;
              final savingRate = budget.amount == 0 ? 0.0 : ((budget.amount - budget.spent) / budget.amount).clamp(-5, 5);
              final accentColor = isOverspent
                  ? Colors.red.shade500
                  : remainingRatio <= 0.1
                      ? Colors.red.shade300
                      : remainingRatio <= 0.2
                          ? Colors.orange.shade400
                          : SBColors.primary;

              return Column(
                children: [
                  // Balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF0BB56A), const Color(0xFF1E9966)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0BB56A).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Balance disponible',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.currency(budget.remaining, currency: budget.currency),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'En tu cuenta',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          title: 'Ingresos',
                          value: '+${Formatters.currency(budget.amount, currency: budget.currency)}',
                          color: const Color(0xFF0BB56A),
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStatCard(
                          title: 'Gastos',
                          value: '-${Formatters.currency(budget.spent, currency: budget.currency)}',
                          color: Colors.red.shade500,
                          icon: Icons.trending_down_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // SmartScore style card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0BB56A).withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.trending_up, color: SBColors.primary),
                                const SizedBox(width: 6),
                                const Text('SmartScore'),
                              ],
                            ),
                            Text(
                              'Tasa de Ahorro',
                              style:
                                  Theme.of(context).textTheme.labelMedium?.copyWith(color: SBColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              smartScoreValue.valueOrNull?.score != null
                                  ? '${smartScoreValue.valueOrNull!.score}'
                                  : '100',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: SBColors.primary, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(savingRate * 100).clamp(-999, 999).toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: SBColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          'Progreso',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: budget.amount == 0 ? 0 : progress,
                          backgroundColor: SBColors.secondary.withValues(alpha: 0.2),
                          color: SBColors.primary,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${Formatters.currency(budget.spent, currency: budget.currency)} / ${Formatters.currency(budget.amount, currency: budget.currency)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.muted),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SBColors.light,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            isOverspent
                                ? 'Ajusta el ritmo para recuperar el control este mes.'
                                : '¡Excelente manejo! Sigues ahorrando de manera efectiva.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SBColors.dark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    return StreamBuilder<int>(
                      stream: Stream.periodic(const Duration(milliseconds: 900), (tick) => tick),
                      initialData: 0,
                      builder: (context, snapshot) {
                        final pulse = (snapshot.data ?? 0) % 2 == 0;
                        final severityColor = alert != null ? _alertColor(alert.severity) : SBColors.muted;
                        final bgColor = alert != null
                            ? severityColor.withValues(alpha: pulse ? 0.16 : 0.08)
                            : SBColors.light;
                        final borderColor = alert != null ? severityColor.withValues(alpha: 0.4) : SBColors.light;
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: borderColor),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 450),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: alert != null
                                  ? [
                                      BoxShadow(
                                        color: severityColor.withValues(alpha: pulse ? 0.25 : 0.12),
                                        blurRadius: pulse ? 14 : 10,
                                        spreadRadius: pulse ? 1 : 0,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Alertas'),
                                    if (alert != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.warning_amber_rounded,
                                          size: 18, color: severityColor.withValues(alpha: 0.9)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (alert != null) ...[
                                  Text(
                                    alert.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: severityColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alert.message,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: severityColor),
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

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(color: SBColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Registrados en el mes',
            style: textTheme.bodySmall?.copyWith(color: SBColors.muted),
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
