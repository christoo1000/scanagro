import 'package:agro_ai_doctor/features/scan/presentation/providers/scan_provider.dart';
import 'package:agro_ai_doctor/features/settings/domain/app_settings.dart';
import 'package:agro_ai_doctor/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _cropController;
  late final TextEditingController _regionController;
  bool _isSavingFarmContext = false;
  bool _isClearingHistory = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _cropController = TextEditingController(text: settings.defaultCrop);
    _regionController = TextEditingController(text: settings.farmRegion);
  }

  @override
  void dispose() {
    _cropController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SettingsSection(
            title: 'Farm context',
            subtitle: 'Used to personalize crop advice without requiring an account.',
            child: Column(
              children: [
                TextField(
                  controller: _cropController,
                  textInputAction: TextInputAction.next,
                  maxLength: 48,
                  decoration: const InputDecoration(
                    labelText: 'Default crop',
                    hintText: 'Maize, tomato, cassava',
                    prefixIcon: Icon(Icons.eco_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _regionController,
                  textInputAction: TextInputAction.done,
                  maxLength: 64,
                  decoration: const InputDecoration(
                    labelText: 'Farm region',
                    hintText: 'Lagos, Kaduna, Enugu',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FarmingMode>(
                  initialValue: settings.farmingMode,
                  decoration: const InputDecoration(
                    labelText: 'Farming mode',
                    prefixIcon: Icon(Icons.agriculture_outlined),
                  ),
                  items: FarmingMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _saveFarmContext(farmingMode: value);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSavingFarmContext
                        ? null
                        : () => _saveFarmContext(
                              farmingMode: settings.farmingMode,
                            ),
                    icon: _isSavingFarmContext
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save farm context'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Scan preferences',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save scan history'),
                  subtitle: const Text('Keep recent diagnoses on this device.'),
                  value: settings.saveScanHistory,
                  onChanged: (value) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSaveScanHistory(value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save crop image paths'),
                  subtitle: const Text(
                    'Stores local image references with history entries.',
                  ),
                  value: settings.saveCropImages,
                  onChanged: settings.saveScanHistory
                      ? (value) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateSaveCropImages(value);
                        }
                      : null,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Confidence warning threshold'),
                  subtitle: Slider(
                    value: settings.confidenceWarningThreshold,
                    min: 0.1,
                    max: 0.95,
                    divisions: 17,
                    label:
                        '${(settings.confidenceWarningThreshold * 100).round()}%',
                    onChanged: (value) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateConfidenceWarningThreshold(value);
                    },
                  ),
                  trailing: Text(
                    '${(settings.confidenceWarningThreshold * 100).round()}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Data and privacy',
            subtitle: 'No account data is managed here. These controls are local.',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Clear scan history'),
                  subtitle: const Text('Deletes locally stored diagnosis history.'),
                  trailing: _isClearingHistory
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _isClearingHistory ? null : _confirmClearHistory,
                ),
                const Divider(height: 24),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy note'),
                  subtitle: Text(
                    'Scan preferences and farm context stay on this device. AI advice may use network services when available.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'App preferences',
            child: Column(
              children: [
                DropdownButtonFormField<AppThemePreference>(
                  initialValue: settings.themePreference,
                  decoration: const InputDecoration(
                    labelText: 'Theme',
                    prefixIcon: Icon(Icons.contrast_outlined),
                  ),
                  items: AppThemePreference.values
                      .map(
                        (themePreference) => DropdownMenuItem(
                          value: themePreference,
                          child: Text(themePreference.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateThemePreference(value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UnitSystem>(
                  initialValue: settings.unitSystem,
                  decoration: const InputDecoration(
                    labelText: 'Units',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  items: UnitSystem.values
                      .map(
                        (unitSystem) => DropdownMenuItem(
                          value: unitSystem,
                          child: Text(unitSystem.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    ref.read(appSettingsProvider.notifier).updateUnitSystem(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: 'About',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline_rounded),
              title: Text('AgroAI Doctor'),
              subtitle: Text(
                'Version 1.0.0. AI diagnosis is a field triage tool and should not replace local agronomist confirmation.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFarmContext({required FarmingMode farmingMode}) async {
    final crop = _cropController.text.trim();
    final region = _regionController.text.trim();

    if (crop.length > 48 || region.length > 64) {
      _showSnackBar('Farm context is too long.', isError: true);
      return;
    }

    setState(() => _isSavingFarmContext = true);
    try {
      await ref.read(appSettingsProvider.notifier).updateFarmContext(
            defaultCrop: crop,
            farmRegion: region,
            farmingMode: farmingMode,
          );
      if (!mounted) return;
      _showSnackBar('Farm context saved.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Could not save farm context.', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingFarmContext = false);
    }
  }

  Future<void> _confirmClearHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear scan history?'),
          content: const Text(
            'This removes saved diagnoses from this device. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    setState(() => _isClearingHistory = true);
    try {
      await ref.read(scanRepositoryProvider).clearScanHistory();
      ref.invalidate(scanHistoryProvider);
      if (!mounted) return;
      _showSnackBar('Scan history cleared.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Could not clear scan history.', isError: true);
    } finally {
      if (mounted) setState(() => _isClearingHistory = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SettingsSection({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
