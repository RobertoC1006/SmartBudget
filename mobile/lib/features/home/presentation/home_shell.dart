import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/presentation/login_page.dart';
import 'budget_page.dart';
import 'expenses_page.dart';
import 'goals_page.dart';
import 'overview_page.dart';
import 'profile_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  final _pages = const [
    OverviewPage(),
    BudgetPage(),
    ExpensesPage(),
    GoalsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final authValue = ref.watch(authControllerProvider);
    final user = authValue.valueOrNull;
    if (user == null) {
      return const LoginPage();
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        elevation: 8,
        surfaceTintColor: Colors.white,
        indicatorColor: SBColors.primary.withValues(alpha: 0.15),
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Presupuesto'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Gastos'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Metas'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
