import '../core/models/ai_response.dart';

/// Maps [VoiceContext] to appropriate ElevenLabs premade voice IDs.
///
/// Based on ElevenLabs premade voices optimized for specific use cases.
/// Voice selection ensures the most natural and contextually appropriate
/// voice is used for each type of response.
class VoiceSelector {
  /// Selects the most appropriate voice ID based on the given [VoiceContext].
  ///
  /// Returns a premade ElevenLabs voice ID optimized for the context.
  static String selectVoice(VoiceContext context) {
    switch (context) {
      case VoiceContext.conversational:
        // Rachel - calm, matter-of-fact, personable woman
        // Perfect for casual conversations and general queries
        return '21m00Tcm4TlvDq8ikWAM';

      case VoiceContext.narration:
        // Adam - deep, authoritative male voice
        // Excellent for storytelling and narration
        return 'pNInz6obpgDQGcFmaJgB';

      case VoiceContext.news:
        // Drew - well-rounded male voice optimized for news
        return '29vD33N1CtxCmqQRPOHJ';

      case VoiceContext.meditation:
        // Emily - calm, soothing female voice
        // Perfect for relaxation and meditation guidance
        return 'LcfcDJNUP1GQjkzn1xUU';

      case VoiceContext.videoGames:
        // Clyde - war veteran, hoarse male voice
        // Great for character-like, energetic responses
        return '2EiwWnXFnvU5JabPnv8n';

      case VoiceContext.audiobook:
        // Matilda - warm, expressive female voice
        // Optimized for long-form reading
        return 'XrExE9yKIg1WjnnlVkGX';

      case VoiceContext.children:
        // Gigi - childish, enthusiastic female voice
        // Perfect for playful, simple responses
        return 'jBpfuIE2acCO8z3wKNLl';

      case VoiceContext.dramatic:
        // George - raspy, intense male voice
        // Excellent for theatrical, emotional delivery
        return 'JBFqnCBsd6RMkjVDRZzb';
    }
  }

  /// Returns a human-readable name for the voice context.
  static String getContextName(VoiceContext context) {
    switch (context) {
      case VoiceContext.conversational:
        return 'Conversational (Rachel)';
      case VoiceContext.narration:
        return 'Narration (Adam)';
      case VoiceContext.news:
        return 'News (Drew)';
      case VoiceContext.meditation:
        return 'Meditation (Emily)';
      case VoiceContext.videoGames:
        return 'Video Games (Clyde)';
      case VoiceContext.audiobook:
        return 'Audiobook (Matilda)';
      case VoiceContext.children:
        return 'Children (Gigi)';
      case VoiceContext.dramatic:
        return 'Dramatic (George)';
    }
  }

  /// Strips ElevenLabs audio tags from text for text-mode display.
  ///
  /// Removes all square-bracketed tags like [whispers], [excited], etc.
  /// while preserving the actual spoken content.
  static String stripAudioTags(String text) {
    // Remove all content within square brackets
    return text.replaceAll(RegExp(r'\[([^\]]+)\]'), '').trim();
  }
}
