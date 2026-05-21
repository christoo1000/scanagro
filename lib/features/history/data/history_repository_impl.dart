import 'package:agro_ai_doctor/features/scan/domain/entities/crop_diagnosis.dart';
import 'package:agro_ai_doctor/features/scan/data/models/crop_diagnosis_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class HistoryRepository {
  Future<List<CropDiagnosis>> getScanHistory(String userId);
  Future<void> saveDiagnosis(String userId, CropDiagnosis diagnosis);
}

class HistoryRepositoryImpl implements HistoryRepository {
  final SupabaseClient supabase;

  HistoryRepositoryImpl({required this.supabase});

  @override
  Future<List<CropDiagnosis>> getScanHistory(String userId) async {
    final response = await supabase
        .from('scan_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => CropDiagnosisModel.fromJson(e)).toList();
  }

  @override
  Future<void> saveDiagnosis(String userId, CropDiagnosis diagnosis) async {
    final model = diagnosis as CropDiagnosisModel;
    await supabase.from('scan_history').insert({
      'user_id': userId,
      ...model.toJson(),
    });
  }
}
