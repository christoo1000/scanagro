import 'dart:convert';

import 'package:agro_ai_doctor/core/config/mistral_config.dart';
import 'package:agro_ai_doctor/features/scan/data/models/diagnosis_explanation.dart';
import 'package:agro_ai_doctor/features/scan/domain/entities/crop_diagnosis.dart';
import 'package:dio/dio.dart';

class DiagnosisExplanationDataSource {
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

  DiagnosisExplanationDataSource({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 10);
  }

  Future<DiagnosisExplanation> explain(CropDiagnosis diagnosis) async {
    if (mistralApiKey.isNotEmpty) {
      return _explainWithMistral(diagnosis);
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/explain',
        data: {
          'disease': diagnosis.diseaseName,
          'confidence': diagnosis.confidenceScore,
          'severity': diagnosis.severity.name == 'severe' ? 'high' : diagnosis.severity.name,
          'is_confident': diagnosis.isConfident,
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
        throw Exception('AI explanation returned an empty response.');
      }

      return DiagnosisExplanation.fromJson(data);
    } on DioException catch (error) {
      final detail = error.response?.data is Map<String, dynamic>
          ? (error.response?.data as Map<String, dynamic>)['detail']
          : null;
      throw Exception(detail ?? error.message ?? 'AI explanation is unavailable.');
    }
  }

  Future<DiagnosisExplanation> _explainWithMistral(CropDiagnosis diagnosis) async {
    final severity = diagnosis.severity.name == 'severe' ? 'high' : diagnosis.severity.name;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        mistralApiUrl,
        data: {
          'model': mistralModel,
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content': 'You produce concise agricultural guidance as one valid JSON object with no markdown.',
            },
            {
              'role': 'user',
              'content': '''
You are an agricultural extension assistant for smallholder farmers.

Diagnosis result:
- Predicted disease/class: ${diagnosis.diseaseName}
- Model confidence: ${(diagnosis.confidenceScore * 100).toStringAsFixed(1)}%
- Confidence severity: $severity
- Is confident: ${diagnosis.isConfident}

Task:
Explain the result in simple English. Give practical next steps a farmer can understand.

Rules:
- Do not invent exact chemical dosages.
- Do not claim the AI result is a final laboratory diagnosis.
- If confidence is low, clearly say the image should be retaken or checked by an agronomist.
- Return valid JSON only.

JSON schema:
{
  "plain_explanation": "short farmer-friendly explanation",
  "confidence_note": "what the confidence means",
  "action_steps": ["3 to 5 immediate steps"],
  "prevention_tips": ["2 to 4 prevention tips"],
  "when_to_seek_help": "when to contact an extension officer/agronomist",
  "safety_note": "short warning about treatment and chemical use"
}
''',
            },
          ],
          'temperature': 0.2,
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

      return _parseExplanation(content);
    } on FormatException {
      throw Exception('Mistral returned explanation in an unexpected format.');
    } on DioException catch (error) {
      throw Exception(error.message ?? 'Mistral explanation is unavailable.');
    }
  }

  DiagnosisExplanation _parseExplanation(String content) {
    final cleaned = _stripMarkdownFence(content.trim());

    try {
      final decoded = json.decode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return DiagnosisExplanation.fromJson(decoded);
      }
    } on FormatException {
      final jsonObject = _extractJsonObject(cleaned);
      if (jsonObject != null) {
        final decoded = json.decode(jsonObject);
        if (decoded is Map<String, dynamic>) {
          return DiagnosisExplanation.fromJson(decoded);
        }
      }
    }

    return DiagnosisExplanation(
      plainExplanation: cleaned,
      confidenceNote: 'The AI returned an unstructured explanation.',
      actionSteps: const [],
      preventionTips: const [],
      whenToSeekHelp: 'Contact an extension officer or agronomist if symptoms spread or the plant gets worse.',
      safetyNote: 'Do not apply chemicals without checking the product label or local expert advice.',
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
