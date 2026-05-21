import 'dart:io';
import 'package:agro_ai_doctor/features/scan/domain/entities/crop_diagnosis.dart';
import 'package:agro_ai_doctor/features/scan/domain/repositories/scan_repository.dart';
import 'package:agro_ai_doctor/features/scan/data/datasources/scan_local_datasource.dart';
import 'package:agro_ai_doctor/features/scan/data/models/crop_diagnosis_model.dart';

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
    final diagnosis = await localDataSource.diagnoseImage(image);
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
    final model = diagnosis as CropDiagnosisModel;
    final history = _readHistoryModels();
    history.insert(0, model);

    final encodedHistory = history
        .take(50)
        .map((item) => json.encode(item.toJson()))
        .toList();

    await sharedPreferences.setStringList(_historyKey, encodedHistory);
  }
}
