import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app.dart';
import 'package:mobile/core/runtime_config.dart';
import 'package:mobile/data/models/user.dart';
import 'package:mobile/features/auth/controllers/auth_controller.dart';

class _FakeAuthController extends AuthController {
  @override
  FutureOr<User?> build() => null;

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({required String fullName, required String email, required String password}) async {}

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('Login screen renders with fake providers', (tester) async {
    final config = RuntimeConfig(apiBaseUrl: 'http://localhost:8000/api', ocrWebhookUrl: null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runtimeConfigProvider.overrideWithValue(config),
          authControllerProvider.overrideWith(() => _FakeAuthController()),
        ],
        child: const SmartBudgetApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SmartBudget+'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
