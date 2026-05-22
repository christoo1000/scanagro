import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/diagnosis_explanation_datasource.dart';
import '../../data/models/diagnosis_explanation.dart';
import '../../domain/entities/crop_diagnosis.dart';
import '../../domain/entities/recommendation.dart';

class ResultScreen extends StatefulWidget {
  final CropDiagnosis diagnosis;

  const ResultScreen({super.key, required this.diagnosis});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _explanationDataSource = DiagnosisExplanationDataSource();
  Future<DiagnosisExplanation>? _explanationFuture;

  void _loadAiExplanation() {
    setState(() {
      _explanationFuture = _explanationDataSource.explain(widget.diagnosis);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ResultHeader(diagnosis: widget.diagnosis),
            const SizedBox(height: 32),
            _AIExplanationSection(
              explanationFuture: _explanationFuture,
              onLoad: _loadAiExplanation,
            ),
            const SizedBox(height: 32),
            _RecommendationsSection(recommendations: widget.diagnosis.recommendations),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _AIExplanationSection extends StatelessWidget {
  final Future<DiagnosisExplanation>? explanationFuture;
  final VoidCallback onLoad;

  const _AIExplanationSection({
    required this.explanationFuture,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    final future = explanationFuture;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (future == null)
            _buildAiPrompt(context)
          else
            FutureBuilder<DiagnosisExplanation>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      style: GoogleFonts.dmSans(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final explanation = snapshot.data;
                if (explanation == null) return const SizedBox.shrink();

                return _ExplanationCard(explanation: explanation);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAiPrompt(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[700]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLoad,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deep AI Analysis',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Get a detailed explanation and more tips',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final DiagnosisExplanation explanation;

  const _ExplanationCard({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              explanation.plainExplanation,
              style: GoogleFonts.dmSans(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildDetailSection(context, 'Next Steps', Icons.playlist_add_check_rounded, explanation.actionSteps),
            const SizedBox(height: 20),
            _buildDetailSection(context, 'Prevention', Icons.shield_outlined, explanation.preventionTips),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      explanation.whenToSeekHelp,
                      style: GoogleFonts.dmSans(fontSize: 13, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, IconData icon, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Icon(Icons.circle, size: 6, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final CropDiagnosis diagnosis;

  const _ResultHeader({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(diagnosis.severity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              diagnosis.severity.name.toUpperCase(),
              style: GoogleFonts.dmSans(
                color: severityColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            diagnosis.diseaseName,
            style: GoogleFonts.dmSans(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, size: 18, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                'AI Confidence: ${(diagnosis.confidenceScore * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            diagnosis.recommendationMessage,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.low: return Colors.green[700]!;
      case SeverityLevel.medium: return Colors.orange[700]!;
      case SeverityLevel.high: return Colors.deepOrange[700]!;
      case SeverityLevel.severe: return Colors.red[700]!;
    }
  }
}

class _RecommendationsSection extends StatelessWidget {
  final List<Recommendation> recommendations;

  const _RecommendationsSection({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Solutions',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => _RecommendationCard(recommendation: rec)),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(recommendation.type),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.description,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            if (recommendation.localizedChemicalNames.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recommendation.localizedChemicalNames
                    .map<Widget>((name) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            name,
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'chemical': return Icons.science_rounded;
      case 'biological': return Icons.nature_rounded;
      default: return Icons.check_circle_outline_rounded;
    }
  }
}
