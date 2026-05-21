import 'package:agro_ai_doctor/features/scan/domain/entities/crop_diagnosis.dart';
import 'package:agro_ai_doctor/features/scan/presentation/providers/scan_provider.dart';
import 'package:agro_ai_doctor/features/scan/presentation/screens/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(scanHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: historyState.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('No scans yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _HistoryTile(diagnosis: history[index]);
            },
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final CropDiagnosis diagnosis;

  const _HistoryTile({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      title: Text(diagnosis.diseaseName),
      subtitle: Text(
        '${(diagnosis.confidenceScore * 100).toStringAsFixed(1)}% confidence - ${diagnosis.createdAt.toLocal()}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(diagnosis: diagnosis)),
        );
      },
    );
  }
}
