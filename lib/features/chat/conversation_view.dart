import 'package:flutter/material.dart';

import '../../core/models/message.dart';
import '../../services/audio_player_service.dart';
import '../../theme/scifi_theme.dart';
import 'widgets/kevin_bubble.dart';
import 'widgets/suggestion_card_grid.dart';
import 'widgets/user_bubble.dart';
import 'widgets/voice_note_bubble.dart';

/// Displays the conversation history as a scrollable list of message bubbles.
///
/// When [messages] is empty, shows [SuggestionCardGrid] as the empty state.
/// When [messages] is non-empty, renders each message as the appropriate bubble
/// widget and auto-scrolls to the most recent message on new additions.
///
/// Message type routing:
/// - [MessageType.text] + [MessageRole.user] → [UserBubble]
/// - [MessageType.text] + [MessageRole.kevin] → [KevinBubble]
/// - [MessageType.voiceNote] or [MessageType.audioGeneration] → [VoiceNoteBubble]
/// - [MessageType.error] → [KevinBubble] (error state)
class ConversationView extends StatefulWidget {
  final List<Message> messages;
  final AudioPlayerService audioPlayerService;

  /// Called when a suggestion card is tapped; receives the card's prompt text.
  final void Function(String promptText) onSuggestionTap;

  /// Called when the retry button is tapped on an error [KevinBubble].
  final void Function(Message message) onRetry;

  const ConversationView({
    super.key,
    required this.messages,
    required this.audioPlayerService,
    required this.onSuggestionTap,
    required this.onRetry,
  });

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ConversationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(Message message) {
    if (message.type == MessageType.voiceNote ||
        message.type == MessageType.audioGeneration) {
      return VoiceNoteBubble(
        message: message,
        audioPlayerService: widget.audioPlayerService,
      );
    }

    if (message.type == MessageType.text && message.role == MessageRole.user) {
      return UserBubble(message: message);
    }

    // MessageType.text + MessageRole.kevin, or MessageType.error
    return KevinBubble(
      message: message,
      onRetry: () => widget.onRetry(message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SciFiTheme.colorBackground,
      child: widget.messages.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SuggestionCardGrid(onCardTap: widget.onSuggestionTap),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(widget.messages[index]),
            ),
    );
  }
}
