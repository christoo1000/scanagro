import 'dart:io';
import 'package:agro_ai_doctor/features/scan/domain/entities/crop_diagnosis.dart';
import 'package:agro_ai_doctor/features/scan/domain/repositories/scan_repository.dart';
import 'package:agro_ai_doctor/features/scan/data/datasources/scan_local_datasource.dart';
import 'package:agro_ai_doctor/features/scan/data/models/crop_diagnosis_model.dart';
import 'package:agro_ai_doctor/features/settings/data/app_settings_keys.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanRepositoryImpl implements ScanRepository {
  final ScanLocalDataSource localDataSource;
  final SharedPreferences sharedPreferences;

  ScanRepositoryImpl({
    required this.localDataSource,
    required this.sharedPreferences,
  });

  @override
  Future<CropDiagnosis> diagnoseImage(File image) async {
    final diagnosis = _applyConfidenceThreshold(
      await localDataSource.diagnoseImage(image),
    );
    await saveDiagnosis(diagnosis);
    return diagnosis;
  }

  static const _historyKey = 'scan_history';

  List<CropDiagnosisModel> _readHistoryModels() {
    final rawHistory = sharedPreferences.getStringList(_historyKey) ?? const [];
    return rawHistory
        .map((item) => CropDiagnosisModel.fromJson(json.decode(item) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CropDiagnosis>> getScanHistory() async {
    return _readHistoryModels();
  }

  @override
  Future<void> saveDiagnosis(CropDiagnosis diagnosis) async {
    final shouldSaveHistory = sharedPreferences.getBool(
          AppSettingsKeys.saveScanHistory,
        ) ??
        true;

    if (!shouldSaveHistory) return;

    final model = diagnosis as CropDiagnosisModel;
    final history = _readHistoryModels();
    history.insert(0, _historySafeModel(model));

    final encodedHistory = history
        .take(50)
        .map((item) => json.encode(item.toJson()))
        .toList();

    await sharedPreferences.setStringList(_historyKey, encodedHistory);
  }

  @override
  Future<void> clearScanHistory() async {
    await sharedPreferences.remove(_historyKey);
  }

  CropDiagnosisModel _historySafeModel(CropDiagnosisModel model) {
    final shouldSaveImages = sharedPreferences.getBool(
          AppSettingsKeys.saveCropImages,
        ) ??
        false;

    if (shouldSaveImages || model.imageUrl.isEmpty) return model;

    return CropDiagnosisModel(
      id: model.id,
      diseaseName: model.diseaseName,
      confidenceScore: model.confidenceScore,
      severity: model.severity,
      isConfident: model.isConfident,
      recommendationMessage: model.recommendationMessage,
      imageUrl: '',
      description: model.description,
      recommendations: model.recommendations,
      createdAt: model.createdAt,
    );
  }

  CropDiagnosisModel _applyConfidenceThreshold(CropDiagnosisModel model) {
    final threshold = sharedPreferences.getDouble(
          AppSettingsKeys.confidenceWarningThreshold,
        ) ??
        0.5;
    final isConfident = model.confidenceScore >= threshold;

    if (model.isConfident == isConfident) return model;

    return CropDiagnosisModel(
      id: model.id,
      diseaseName: model.diseaseName,
      confidenceScore: model.confidenceScore,
      severity: model.severity,
      isConfident: isConfident,
      recommendationMessage: isConfident
          ? model.recommendationMessage
          : 'Prediction is below your confidence threshold. Retake the image in better lighting and confirm symptoms before treatment.',
      imageUrl: model.imageUrl,
      description: model.description,
      recommendations: model.recommendations,
      createdAt: model.createdAt,
    );
  }
}
