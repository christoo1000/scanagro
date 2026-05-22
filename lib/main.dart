import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/scan/presentation/screens/home_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'features/scan/presentation/providers/scan_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const AgroAIDoctorApp(),
    ),
  );
}

class AgroAIDoctorApp extends ConsumerWidget {
  const AgroAIDoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp(
      title: 'AgroAI Doctor',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themePreference.themeMode,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
