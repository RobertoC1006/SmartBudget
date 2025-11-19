import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/runtime_config.dart';
import '../models/expense.dart';
import '../models/ocr_scan_result.dart';

class ExpenseRepository {
  ExpenseRepository(this._dio, this._config);

  final Dio _dio;
  final RuntimeConfig _config;

  Future<List<Expense>> fetchExpenses({ExpenseCategory? category, String? budgetId}) async {
    try {
      final response = await _dio.get(
        '/expenses',
        queryParameters: {
          if (category != null) 'category': category.value,
          if (budgetId != null) 'budget_id': budgetId,
        },
      );
      final data = response.data as List<dynamic>;
      return data.map((json) => Expense.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible obtener los gastos');
    }
  }

  Future<Expense> createExpense(ExpenseDraft draft) async {
    try {
      final response = await _dio.post('/expenses/', data: draft.toJson());
      return Expense.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw error.error ?? ApiException(error.message ?? 'No fue posible registrar el gasto');
    }
  }

  Future<OcrScanResult> runAutomation(File file) async {
    final webhookUrl = _config.ocrWebhookUrl;
    if (webhookUrl == null || webhookUrl.isEmpty) {
      throw ApiException('Configura ocrWebhookUrl en runtime.json para usar la automatización.');
    }
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
    });
    try {
      final response = await _dio.post<dynamic>(
        webhookUrl,
        data: formData,
        options: Options(
          extra: {'auth': false},
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
        ),
      );
      final payload = response.data;
      return _normalizeAutomationPayload(payload);
    } on DioException catch (error) {
      final exception = error.error ?? ApiException(error.message ?? 'La automatización devolvió un error.');
      throw exception;
    }
  }

  OcrScanResult _normalizeAutomationPayload(dynamic payload) {
    dynamic source = payload;
    if (payload is String && payload.trim().isNotEmpty) {
      try {
        source = jsonDecode(payload);
      } catch (_) {
        return OcrScanResult(
          rawText: payload,
          payload: payload,
        );
      }
    }
    if (source is List && source.isNotEmpty) {
      source = source.first;
    }

    Map<String, dynamic>? candidate;
    if (source is Map<String, dynamic>) {
      if (source['data'] is Map<String, dynamic>) {
        candidate = Map<String, dynamic>.from(source['data'] as Map<String, dynamic>);
      } else if (source['body'] is Map<String, dynamic>) {
        candidate = Map<String, dynamic>.from(source['body'] as Map<String, dynamic>);
      } else {
        candidate = Map<String, dynamic>.from(source);
      }
    }

    String? resolve(Iterable<String> keys) {
      for (final key in keys) {
        final value = _readNested(candidate, key) ?? _readNested(source, key);
        if (value != null && '$value'.isNotEmpty) {
          return '$value';
        }
      }
      return null;
    }

    final rawAmount = resolve(['amount', 'monto', 'total']);
    final rawCategory = resolve(['category', 'categoria']);
    final rawDate = resolve(['expense_date', 'fecha', 'date']);
    final rawText = resolve([
      'raw_text',
      'texto',
      'texto_normalizado',
      'ocr_text',
      'full_text',
      'ocr.raw',
      'result',
    ]);

    return OcrScanResult(
      description: resolve(['description', 'descripcion']),
      amount: rawAmount != null ? double.tryParse(rawAmount.replaceAll(RegExp('[^0-9.,-]'), '').replaceAll(',', '.')) : null,
      category: _normalizeCategory(rawCategory),
      expenseDate: _normalizeDate(rawDate),
      rawText: rawText ??
          (candidate != null ? const JsonEncoder.withIndent('  ').convert(candidate) : payload.toString()),
      payload: payload,
      provider: 'n8n-webhook',
    );
  }

  DateTime? _normalizeDate(String? value) {
    if (value == null) return null;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return DateTime.tryParse(value);
    }
    final parsed = DateTime.tryParse(value);
    return parsed;
  }

  String? _normalizeCategory(String? value) {
    if (value == null) return null;
    final normalized = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]'), '')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    final map = {
      'alimentacion': 'alimentacion',
      'comida': 'alimentacion',
      'supermercado': 'alimentacion',
      'transporte': 'transporte',
      'gasolina': 'transporte',
      'servicios': 'servicios',
      'luz': 'servicios',
      'agua': 'servicios',
      'ocio': 'ocio',
      'entretenimiento': 'ocio',
      'salud': 'salud',
      'educacion': 'educacion',
      'ropa': 'ropa',
      'vivienda': 'vivienda',
      'otros': 'otros',
      'general': 'general',
    };
    return map[normalized] ?? 'general';
  }

  dynamic _readNested(dynamic obj, String path) {
    if (obj is! Map) return null;
    dynamic current = obj;
    for (final segment in path.split('.')) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final config = ref.watch(runtimeConfigProvider);
  return ExpenseRepository(dio, config);
});
