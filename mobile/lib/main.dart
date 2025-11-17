import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/runtime_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_PE');
  final config = await RuntimeConfig.load();
  runApp(
    ProviderScope(
      overrides: [
        runtimeConfigProvider.overrideWithValue(config),
      ],
      child: const SmartBudgetApp(),
    ),
  );
}
