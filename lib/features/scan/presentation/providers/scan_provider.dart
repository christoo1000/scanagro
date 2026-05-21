import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agro_ai_doctor/features/scan/domain/entities/crop_diagnosis.dart';
import 'package:agro_ai_doctor/features/scan/domain/repositories/scan_repository.dart';
import 'package:agro_ai_doctor/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:agro_ai_doctor/features/scan/data/datasources/scan_local_datasource.dart';

import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Initialized in main
});

final scanLocalDataSourceProvider = Provider<ScanLocalDataSource>((ref) {
  final dataSource = ScanLocalDataSourceImpl();
  ref.onDispose(dataSource.close);
  return dataSource;
});

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  final localDataSource = ref.watch(scanLocalDataSourceProvider);
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return ScanRepositoryImpl(
    localDataSource: localDataSource,
    sharedPreferences: sharedPreferences,
  );
});

final scanStateProvider = StateNotifierProvider<ScanNotifier, AsyncValue<CropDiagnosis?>>((ref) {
  final repository = ref.watch(scanRepositoryProvider);
  return ScanNotifier(repository: repository);
});

final scanHistoryProvider = FutureProvider<List<CropDiagnosis>>((ref) {
  final repository = ref.watch(scanRepositoryProvider);
  return repository.getScanHistory();
});

class ScanNotifier extends StateNotifier<AsyncValue<CropDiagnosis?>> {
  final ScanRepository repository;

  ScanNotifier({required this.repository}) : super(const AsyncValue.data(null));

  Future<void> diagnoseImage(File image) async {
    state = const AsyncValue.loading();
    try {
      final result = await repository.diagnoseImage(image);
      // Keep history views fresh after every successful offline diagnosis.
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
