import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/config/mistral_config.dart';

class MistralCommunityService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.mistral.ai/v1/chat/completions';

  Future<String> fetchSectionContent(String prompt) async {
    final response = await _dio.post(
      _baseUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${MistralConfig.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: jsonEncode({
        'model': MistralConfig.model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 400,
        'temperature': 0.7,
      }),
    );
    if (response.statusCode == 200) {
      final data = response.data;
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Failed to fetch content');
    }
  }
}
