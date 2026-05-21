import 'dart:io';
import 'package:agro_ai_doctor/features/scan/domain/entities/crop_diagnosis.dart';

abstract class ScanRepository {
  Future<CropDiagnosis> diagnoseImage(File image);
  Future<List<CropDiagnosis>> getScanHistory();
  Future<void> saveDiagnosis(CropDiagnosis diagnosis);
}
