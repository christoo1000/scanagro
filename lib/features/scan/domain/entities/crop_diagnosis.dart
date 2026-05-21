import 'package:agro_ai_doctor/features/scan/domain/entities/recommendation.dart';

enum SeverityLevel { low, medium, high, severe }

class CropDiagnosis {
  final String id;
  final String diseaseName;
  final double confidenceScore;
  final SeverityLevel severity;
  final bool isConfident;
  final String recommendationMessage;
  final String imageUrl;
  final String description;
  final List<Recommendation> recommendations;
  final DateTime createdAt;

  CropDiagnosis({
    required this.id,
    required this.diseaseName,
    required this.confidenceScore,
    required this.severity,
    required this.isConfident,
    required this.recommendationMessage,
    required this.imageUrl,
    required this.description,
    required this.recommendations,
    required this.createdAt,
  });
}
