import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/models/suggestion_card.dart';
import 'suggestion_card_widget.dart';

/// Default suggestion cards displayed in the empty state.
const List<SuggestionCard> kDefaultSuggestionCards = [
  SuggestionCard(
    id: 'default_1',
    label: 'Generate Heavy Metal BGM',
    promptText: 'Generate a Heavy Metal BGM for an Action Game',
    category: SuggestionCategory.elevenLabs,
  ),
  SuggestionCard(
    id: 'default_2',
    label: 'Thunderstorm SFX',
    promptText: 'Create a sound effect of a thunderstorm',
    category: SuggestionCategory.elevenLabs,
  ),
  SuggestionCard(
    id: 'default_3',
    label: 'Dramatic voice read',
    promptText: 'Read this text in a dramatic voice: [text]',
    category: SuggestionCategory.elevenLabs,
  ),
  SuggestionCard(
    id: 'default_4',
    label: 'Open Spotify',
    promptText: 'Open Spotify',
    category: SuggestionCategory.osAction,
  ),
  SuggestionCard(
    id: 'default_5',
    label: 'Wi-Fi Settings',
    promptText: 'Open Wi-Fi settings',
    category: SuggestionCategory.osAction,
  ),
  SuggestionCard(
    id: 'default_6',
    label: 'What time is it?',
    promptText: 'What time is it?',
    category: SuggestionCategory.generalQuery,
  ),
  SuggestionCard(
    id: 'default_7',
    label: 'Sci-fi ambience',
    promptText: 'Generate a sci-fi spaceship ambient sound',
    category: SuggestionCategory.elevenLabs,
  ),
  SuggestionCard(
    id: 'default_8',
    label: 'Capital of France',
    promptText: 'What is the capital of France?',
    category: SuggestionCategory.generalQuery,
  ),
];

/// Displays suggestion cards in a 2-column layout with animated rotation.
///
/// Cards animate in with a fade + slide effect, display for 4 seconds,
/// then animate out and are replaced with the next set of cards.
/// Shows 6 cards at a time, cycling through all available cards.
class SuggestionCardGrid extends StatefulWidget {
  final void Function(String promptText) onCardTap;

  const SuggestionCardGrid({super.key, required this.onCardTap});

  @override
  State<SuggestionCardGrid> createState() => _SuggestionCardGridState();
}

class _SuggestionCardGridState extends State<SuggestionCardGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _rotationTimer;
  int _currentSetIndex = 0;
  List<SuggestionCard> _visibleCards = [];

  static const int _cardsPerSet = 6;
  static const Duration _displayDuration = Duration(seconds: 5);
  static const Duration _animationDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _updateVisibleCards();
    _controller.forward();
    _startRotationTimer();
  }

  void _updateVisibleCards() {
    final startIndex =
        (_currentSetIndex * _cardsPerSet) % kDefaultSuggestionCards.length;
    _visibleCards = [];

    for (int i = 0; i < _cardsPerSet; i++) {
      final index = (startIndex + i) % kDefaultSuggestionCards.length;
      _visibleCards.add(kDefaultSuggestionCards[index]);
    }
  }

  void _startRotationTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer(_displayDuration, _rotateCards);
  }

  Future<void> _rotateCards() async {
    if (!mounted) return;

    // Animate out
    await _controller.reverse();

    if (!mounted) return;

    // Update to next set
    setState(() {
      _currentSetIndex =
          (_currentSetIndex + 1) %
          ((kDefaultSuggestionCards.length / _cardsPerSet).ceil());
      _updateVisibleCards();
    });

    // Animate in
    await _controller.forward();

    if (mounted) {
      _startRotationTimer();
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth =
        (MediaQuery.of(context).size.width - 48) /
        2; // 16px padding each side + 16px gap

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: _visibleCards.map((card) {
              return SizedBox(
                width: cardWidth,
                child: SuggestionCardWidget(
                  card: card,
                  onTap: widget.onCardTap,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
