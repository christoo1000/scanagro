import 'package:agro_ai_doctor/features/scan/presentation/providers/scan_provider.dart';
import 'package:agro_ai_doctor/features/settings/data/app_settings_keys.dart';
import 'package:agro_ai_doctor/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return AppSettingsNotifier(sharedPreferences);
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _sharedPreferences;

  AppSettingsNotifier(this._sharedPreferences) : super(AppSettings.defaults()) {
    state = _load();
  }

  AppSettings _load() {
    final defaults = AppSettings.defaults();

    return AppSettings(
      defaultCrop:
          _sharedPreferences.getString(AppSettingsKeys.defaultCrop) ??
              defaults.defaultCrop,
      farmRegion:
          _sharedPreferences.getString(AppSettingsKeys.farmRegion) ??
              defaults.farmRegion,
      farmingMode: _readEnum(
        AppSettingsKeys.farmingMode,
        FarmingMode.values,
        defaults.farmingMode,
      ),
      saveScanHistory:
          _sharedPreferences.getBool(AppSettingsKeys.saveScanHistory) ??
              defaults.saveScanHistory,
      saveCropImages:
          _sharedPreferences.getBool(AppSettingsKeys.saveCropImages) ??
              defaults.saveCropImages,
      confidenceWarningThreshold: _readThreshold(defaults),
      themePreference: _readEnum(
        AppSettingsKeys.themePreference,
        AppThemePreference.values,
        defaults.themePreference,
      ),
      unitSystem: _readEnum(
        AppSettingsKeys.unitSystem,
        UnitSystem.values,
        defaults.unitSystem,
      ),
    );
  }

  T _readEnum<T extends Enum>(String key, List<T> values, T fallback) {
    final rawValue = _sharedPreferences.getString(key);
    if (rawValue == null) return fallback;

    for (final value in values) {
      if (value.name == rawValue) return value;
    }

    debugPrint('Invalid persisted setting for $key: $rawValue');
    return fallback;
  }

  double _readThreshold(AppSettings defaults) {
    final rawValue =
        _sharedPreferences.getDouble(AppSettingsKeys.confidenceWarningThreshold);

    if (rawValue == null) return defaults.confidenceWarningThreshold;
    if (rawValue < 0.1 || rawValue > 0.95) {
      debugPrint('Invalid confidence threshold persisted: $rawValue');
      return defaults.confidenceWarningThreshold;
    }

    return rawValue;
  }

  Future<void> updateFarmContext({
    required String defaultCrop,
    required String farmRegion,
    required FarmingMode farmingMode,
  }) async {
    final sanitizedCrop = _sanitizeText(defaultCrop, maxLength: 48);
    final sanitizedRegion = _sanitizeText(farmRegion, maxLength: 64);

    await _sharedPreferences.setString(
      AppSettingsKeys.defaultCrop,
      sanitizedCrop,
    );
    await _sharedPreferences.setString(
      AppSettingsKeys.farmRegion,
      sanitizedRegion,
    );
    await _sharedPreferences.setString(
      AppSettingsKeys.farmingMode,
      farmingMode.name,
    );

    state = state.copyWith(
      defaultCrop: sanitizedCrop,
      farmRegion: sanitizedRegion,
      farmingMode: farmingMode,
    );
  }

  Future<void> updateSaveScanHistory(bool value) async {
    await _sharedPreferences.setBool(AppSettingsKeys.saveScanHistory, value);
    state = state.copyWith(saveScanHistory: value);
  }

  Future<void> updateSaveCropImages(bool value) async {
    await _sharedPreferences.setBool(AppSettingsKeys.saveCropImages, value);
    state = state.copyWith(saveCropImages: value);
  }

  Future<void> updateConfidenceWarningThreshold(double value) async {
    final boundedValue = value.clamp(0.1, 0.95).toDouble();
    await _sharedPreferences.setDouble(
      AppSettingsKeys.confidenceWarningThreshold,
      boundedValue,
    );
    state = state.copyWith(confidenceWarningThreshold: boundedValue);
  }

  Future<void> updateThemePreference(AppThemePreference value) async {
    await _sharedPreferences.setString(
      AppSettingsKeys.themePreference,
      value.name,
    );
    state = state.copyWith(themePreference: value);
  }

  Future<void> updateUnitSystem(UnitSystem value) async {
    await _sharedPreferences.setString(AppSettingsKeys.unitSystem, value.name);
    state = state.copyWith(unitSystem: value);
  }

  String _sanitizeText(String value, {required int maxLength}) {
    final collapsed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.length <= maxLength) return collapsed;
    return collapsed.substring(0, maxLength).trimRight();
  }
}

extension AppThemeMode on AppThemePreference {
  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }
}
