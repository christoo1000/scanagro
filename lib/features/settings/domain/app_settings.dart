enum FarmingMode {
  organic,
  conventional,
  mixed,
}

enum AppThemePreference {
  system,
  light,
  dark,
}

enum UnitSystem {
  metric,
  imperial,
}

class AppSettings {
  final String defaultCrop;
  final String farmRegion;
  final FarmingMode farmingMode;
  final bool saveScanHistory;
  final bool saveCropImages;
  final double confidenceWarningThreshold;
  final AppThemePreference themePreference;
  final UnitSystem unitSystem;

  const AppSettings({
    required this.defaultCrop,
    required this.farmRegion,
    required this.farmingMode,
    required this.saveScanHistory,
    required this.saveCropImages,
    required this.confidenceWarningThreshold,
    required this.themePreference,
    required this.unitSystem,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      defaultCrop: '',
      farmRegion: '',
      farmingMode: FarmingMode.mixed,
      saveScanHistory: true,
      saveCropImages: false,
      confidenceWarningThreshold: 0.5,
      themePreference: AppThemePreference.system,
      unitSystem: UnitSystem.metric,
    );
  }

  AppSettings copyWith({
    String? defaultCrop,
    String? farmRegion,
    FarmingMode? farmingMode,
    bool? saveScanHistory,
    bool? saveCropImages,
    double? confidenceWarningThreshold,
    AppThemePreference? themePreference,
    UnitSystem? unitSystem,
  }) {
    return AppSettings(
      defaultCrop: defaultCrop ?? this.defaultCrop,
      farmRegion: farmRegion ?? this.farmRegion,
      farmingMode: farmingMode ?? this.farmingMode,
      saveScanHistory: saveScanHistory ?? this.saveScanHistory,
      saveCropImages: saveCropImages ?? this.saveCropImages,
      confidenceWarningThreshold:
          confidenceWarningThreshold ?? this.confidenceWarningThreshold,
      themePreference: themePreference ?? this.themePreference,
      unitSystem: unitSystem ?? this.unitSystem,
    );
  }
}

extension FarmingModeLabel on FarmingMode {
  String get label {
    switch (this) {
      case FarmingMode.organic:
        return 'Organic';
      case FarmingMode.conventional:
        return 'Conventional';
      case FarmingMode.mixed:
        return 'Mixed';
    }
  }
}

extension AppThemePreferenceLabel on AppThemePreference {
  String get label {
    switch (this) {
      case AppThemePreference.system:
        return 'System';
      case AppThemePreference.light:
        return 'Light';
      case AppThemePreference.dark:
        return 'Dark';
    }
  }
}

extension UnitSystemLabel on UnitSystem {
  String get label {
    switch (this) {
      case UnitSystem.metric:
        return 'Metric';
      case UnitSystem.imperial:
        return 'Imperial';
    }
  }
}
