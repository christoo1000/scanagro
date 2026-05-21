class DiagnosisExplanation {
  final String plainExplanation;
  final String confidenceNote;
  final List<String> actionSteps;
  final List<String> preventionTips;
  final String whenToSeekHelp;
  final String safetyNote;

  const DiagnosisExplanation({
    required this.plainExplanation,
    required this.confidenceNote,
    required this.actionSteps,
    required this.preventionTips,
    required this.whenToSeekHelp,
    required this.safetyNote,
  });

  factory DiagnosisExplanation.fromJson(Map<String, dynamic> json) {
    return DiagnosisExplanation(
      plainExplanation: json['plain_explanation'] as String? ?? '',
      confidenceNote: json['confidence_note'] as String? ?? '',
      actionSteps: List<String>.from(json['action_steps'] as List? ?? const []),
      preventionTips: List<String>.from(json['prevention_tips'] as List? ?? const []),
      whenToSeekHelp: json['when_to_seek_help'] as String? ?? '',
      safetyNote: json['safety_note'] as String? ?? '',
    );
  }
}
