import 'dart:io';
import 'package:dio/dio.dart';
import 'package:agro_ai_doctor/features/scan/data/models/crop_diagnosis_model.dart';

abstract class ScanRemoteDataSource {
  Future<CropDiagnosisModel> diagnoseImage(File image);
}

class ScanRemoteDataSourceImpl implements ScanRemoteDataSource {
  final Dio dio;
  static const String baseUrl = String.fromEnvironment(
    'AGROAI_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String apiKey = String.fromEnvironment('AGROAI_API_KEY');

  ScanRemoteDataSourceImpl({required this.dio}) {
    dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 20)
      ..sendTimeout = const Duration(seconds: 20);
  }

  @override
  Future<CropDiagnosisModel> diagnoseImage(File image) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path),
    });

    try {
      final response = await dio.post(
        '/predict',
        data: formData,
        options: Options(
          headers: {
            if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        return CropDiagnosisModel.fromJson(response.data);
      }

      throw Exception('Prediction failed with status ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        final detail = e.response?.data is Map<String, dynamic>
            ? e.response?.data['detail']
            : null;
        throw Exception(detail ?? e.message ?? 'Network error');
      }

      throw Exception('Network error: $e');
    }
  }
}
