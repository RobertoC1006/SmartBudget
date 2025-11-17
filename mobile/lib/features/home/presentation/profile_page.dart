import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../widgets/async_value_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/presentation/login_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authValue = ref.watch(authControllerProvider);
    final user = authValue.valueOrNull;

    if (user == null) {
      return const LoginPage();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Perfil',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                const Divider(height: 24),
                _profileRow('Moneda', user.defaultCurrency),
                _profileRow(
                  'Ingreso mensual',
                  user.monthlyIncome != null
                      ? Formatters.currency(user.monthlyIncome!, currency: user.defaultCurrency)
                      : 'No registrado',
                ),
                _profileRow('Miembro desde', Formatters.date(user.createdAt)),
                _profileRow('Estado', user.isActive ? 'Activo' : 'Inactivo', valueColor: SBColors.primary),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AsyncValueWidget(
          value: authValue,
          builder: (_) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: SBColors.muted)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? SBColors.dark),
          ),
        ],
      ),
    );
  }
}
