import 'package:agro_ai_doctor/features/scan/domain/entities/crop_diagnosis.dart';
import 'package:agro_ai_doctor/features/scan/domain/entities/recommendation.dart';

class CropDiagnosisModel extends CropDiagnosis {
  CropDiagnosisModel({
    required super.id,
    required super.diseaseName,
    required super.confidenceScore,
    required super.severity,
    required super.isConfident,
    required super.recommendationMessage,
    required super.imageUrl,
    required super.description,
    required super.recommendations,
    required super.createdAt,
  });

  factory CropDiagnosisModel.fromJson(Map<String, dynamic> json) {
    final disease = json['disease'] as String? ?? json['disease_name'] as String? ?? 'unknown';
    final confidence = (json['confidence'] as num? ?? json['confidence_score'] as num? ?? 0).toDouble();
    final severity = json['severity'] as String? ?? json['severity_level'] as String? ?? 'low';
    final recommendation = json['recommendation'] as String? ?? 'Confirm symptoms before treatment decisions.';

    return CropDiagnosisModel(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      diseaseName: disease,
      confidenceScore: confidence,
      severity: _parseSeverity(severity),
      isConfident: json['is_confident'] as bool? ?? confidence >= 0.5,
      recommendationMessage: recommendation,
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? _descriptionFor(disease),
      recommendations: _parseRecommendations(json['recommendations'], recommendation),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  factory CropDiagnosisModel.fromLocalPrediction({
    required String disease,
    required double confidence,
    required String severity,
    required bool isConfident,
    required String recommendation,
    required String imagePath,
  }) {
    return CropDiagnosisModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      diseaseName: disease,
      confidenceScore: confidence,
      severity: _parseSeverity(severity),
      isConfident: isConfident,
      recommendationMessage: recommendation,
      imageUrl: imagePath,
      description: _descriptionFor(disease),
      recommendations: _parseRecommendations(null, recommendation),
      createdAt: DateTime.now(),
    );
  }

  static String _descriptionFor(String disease) {
    if (disease.endsWith('_healthy')) {
      return 'The uploaded leaf image appears healthy based on the model prediction.';
    }

    return 'The model detected ${disease.replaceAll('_', ' ')} from the uploaded leaf image.';
  }

  static List<RecommendationModel> _parseRecommendations(
    Object? value,
    String fallbackRecommendation,
  ) {
    if (value is List) {
      return value
          .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [
      RecommendationModel(
        title: 'Field confirmation',
        description: fallbackRecommendation,
        localizedChemicalNames: const [],
        type: 'inspection',
      ),
    ];
  }

  static SeverityLevel _parseSeverity(String level) {
    switch (level.toLowerCase()) {
      case 'low': return SeverityLevel.low;
      case 'medium': return SeverityLevel.medium;
      case 'high': return SeverityLevel.high;
      case 'severe': return SeverityLevel.severe;
      default: return SeverityLevel.low;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disease_name': diseaseName,
      'confidence_score': confidenceScore,
      'severity_level': severity.name,
      'is_confident': isConfident,
      'recommendation': recommendationMessage,
      'image_url': imageUrl,
      'description': description,
      'recommendations': recommendations.map((e) => (e as RecommendationModel).toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class RecommendationModel extends Recommendation {
  RecommendationModel({
    required super.title,
    required super.description,
    required super.localizedChemicalNames,
    required super.type,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      title: json['title'] as String,
      description: json['description'] as String,
      localizedChemicalNames: List<String>.from(json['chemicals'] ?? []),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'chemicals': localizedChemicalNames,
      'type': type,
    };
  }
}
