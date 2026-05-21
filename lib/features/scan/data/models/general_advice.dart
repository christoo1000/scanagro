class GeneralAdvice {
  final String answer;
  final List<String> actionSteps;
  final List<String> cautions;

  const GeneralAdvice({
    required this.answer,
    required this.actionSteps,
    required this.cautions,
  });

  factory GeneralAdvice.fromJson(Map<String, dynamic> json) {
    return GeneralAdvice(
      answer: json['answer'] as String? ?? '',
      actionSteps: List<String>.from(json['action_steps'] as List? ?? const []),
      cautions: List<String>.from(json['cautions'] as List? ?? const []),
    );
  }
}
