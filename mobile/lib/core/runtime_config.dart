import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the runtime configuration that mirrors `window.__SB_RUNTIME_CONFIG__`
/// in the existing web frontend.
class RuntimeConfig {
  RuntimeConfig({
    required this.apiBaseUrl,
    required this.ocrWebhookUrl,
  });

  final String apiBaseUrl;
  final String? ocrWebhookUrl;

  static const _assetPath = 'assets/config/runtime.json';

  static Future<RuntimeConfig> load({String assetPath = _assetPath}) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final baseUrl = (data['apiBaseUrl'] as String?) ?? '';
    if (baseUrl.isEmpty) {
      throw FlutterError('apiBaseUrl is required in $assetPath');
    }
    return RuntimeConfig(
      apiBaseUrl: baseUrl,
      ocrWebhookUrl: data['ocrWebhookUrl'] as String?,
    );
  }
}

final runtimeConfigProvider = Provider<RuntimeConfig>((_) {
  throw UnimplementedError('RuntimeConfig must be provided before runApp');
});
