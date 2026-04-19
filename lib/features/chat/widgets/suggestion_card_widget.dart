import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/suggestion_card.dart';
import '../../../theme/scifi_theme.dart';

/// Maps [SuggestionCategory] to a human-readable sub-label.
String _categoryLabel(SuggestionCategory category) {
  switch (category) {
    case SuggestionCategory.elevenLabs:
      return 'ElevenLabs';
    case SuggestionCategory.osAction:
      return 'OS Action';
    case SuggestionCategory.generalQuery:
      return 'General Query';
  }
}

/// A tappable card that displays a suggestion prompt.
///
/// Black background, red 1dp border, 8dp corner radius.
/// Orbitron label (12sp) and Exo 2 sub-label (10sp, grey).
/// Tapping calls [onTap] with [card.promptText].
class SuggestionCardWidget extends StatelessWidget {
  final SuggestionCard card;
  final void Function(String promptText) onTap;

  const SuggestionCardWidget({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(card.promptText),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: SciFiTheme.colorBackground,
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          border: Border.all(color: SciFiTheme.colorAccent, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.label,
              style: GoogleFonts.orbitron(
                fontSize: 12,
                color: SciFiTheme.colorTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _categoryLabel(card.category),
              style: GoogleFonts.exo2(
                fontSize: 10,
                color: SciFiTheme.colorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
