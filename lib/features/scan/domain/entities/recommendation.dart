class Recommendation {
  final String title;
  final String description;
  final List<String> localizedChemicalNames;
  final String type; // e.g., 'chemical', 'biological', 'preventive'

  Recommendation({
    required this.title,
    required this.description,
    required this.localizedChemicalNames,
    required this.type,
  });
}
