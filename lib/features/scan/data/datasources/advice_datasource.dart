import 'dart:convert';

import 'package:agro_ai_doctor/core/config/mistral_config.dart';
import 'package:agro_ai_doctor/features/scan/data/models/general_advice.dart';
import 'package:dio/dio.dart';

class AdviceDataSource {
  static const String mistralApiUrl = 'https://api.mistral.ai/v1/chat/completions';
  static const String mistralModel = String.fromEnvironment(
    'MISTRAL_MODEL',
    defaultValue: MistralConfig.model,
  );
  static const String mistralApiKey = String.fromEnvironment(
    'MISTRAL_API_KEY',
    defaultValue: MistralConfig.apiKey,
  );
  static const String baseUrl = String.fromEnvironment(
    'AGROAI_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String apiKey = String.fromEnvironment('AGROAI_API_KEY');

  final Dio _dio;

  AdviceDataSource({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 10);
  }

  Future<GeneralAdvice> getAdvice({
    required String question,
    String? crop,
  }) async {
    if (mistralApiKey.isNotEmpty) {
      return _getAdviceFromMistral(question: question, crop: crop);
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/advice',
        data: {
          'question': question,
          if (crop != null && crop.trim().isNotEmpty) 'crop': crop.trim(),
          'language': 'en',
        },
        options: Options(
          headers: {
            if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Advice service returned an empty response.');
      }

      return GeneralAdvice.fromJson(data);
    } on DioException catch (error) {
      final detail = error.response?.data is Map<String, dynamic>
          ? (error.response?.data as Map<String, dynamic>)['detail']
          : null;
      throw Exception(detail ?? error.message ?? 'Advice service is unavailable.');
    }
  }

  Future<GeneralAdvice> _getAdviceFromMistral({
    required String question,
    String? crop,
  }) async {
    final cropContext = crop == null || crop.trim().isEmpty ? 'the farmer crop' : crop.trim();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        mistralApiUrl,
        data: {
          'model': mistralModel,
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an agricultural extension assistant. Return one valid JSON object only, with no markdown.',
            },
            {
              'role': 'user',
              'content': '''
Give practical farming advice in simple English.

Crop context: $cropContext
Farmer question: $question

Rules:
- Be practical for smallholder farmers.
- Do not invent exact chemical dosage.
- Recommend local extension/agronomist support for severe or spreading problems.
- Return valid JSON only.

JSON schema:
{
  "answer": "clear explanation",
  "action_steps": ["3 to 5 practical steps"],
  "cautions": ["1 to 3 safety or uncertainty cautions"]
}
''',
            },
          ],
          'temperature': 0.3,
          'max_tokens': 700,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $mistralApiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      final content = response.data?['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw Exception('Mistral returned an empty response.');
      }

      return _parseAdvice(content);
    } on FormatException {
      throw Exception('Mistral returned advice in an unexpected format.');
    } on DioException catch (error) {
      throw Exception(error.message ?? 'Mistral advice is unavailable.');
    }
  }

  GeneralAdvice _parseAdvice(String content) {
    final cleaned = _stripMarkdownFence(content.trim());

    try {
      final decoded = json.decode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return GeneralAdvice.fromJson(decoded);
      }
    } on FormatException {
      final jsonObject = _extractJsonObject(cleaned);
      if (jsonObject != null) {
        final decoded = json.decode(jsonObject);
        if (decoded is Map<String, dynamic>) {
          return GeneralAdvice.fromJson(decoded);
        }
      }
    }

    return GeneralAdvice(
      answer: cleaned,
      actionSteps: const [],
      cautions: const ['This response was not structured, so review it carefully before taking action.'],
    );
  }

  String _stripMarkdownFence(String value) {
    if (!value.startsWith('```')) return value;

    return value
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  String? _extractJsonObject(String value) {
    final start = value.indexOf('{');
    final end = value.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;

    return value.substring(start, end + 1);
  }
}
