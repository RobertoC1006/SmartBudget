import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_shell.dart';

class SmartBudgetApp extends ConsumerWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SmartBudget+',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('es', 'PE'),
      supportedLocales: const [
        Locale('es', 'PE'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends ConsumerWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authValue = ref.watch(authControllerProvider);
    return authValue.when(
      data: (user) {
        return user != null ? const HomeShell() : const LoginPage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No fue posible validar tu sesión.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => ref.refresh(authControllerProvider),
                child: const Text('Reintentar'),
              ),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }
}
