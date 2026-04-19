enum SuggestionCategory { elevenLabs, osAction, generalQuery }

class SuggestionCard {
  final String id;
  final String label;
  final String promptText;
  final SuggestionCategory category;

  const SuggestionCard({
    required this.id,
    required this.label,
    required this.promptText,
    required this.category,
  });
}
