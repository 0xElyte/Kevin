enum AIIntent {
  generalQuery,
  osAction,
  elevenLabsTTS,
  elevenLabsMusic,
  elevenLabsSFX,
}

enum VoiceContext {
  conversational,
  narration,
  news,
  meditation,
  videoGames,
  audiobook,
  children,
  dramatic,
}

class OSActionSpec {
  final String type; // 'open_app' | 'navigate_settings'
  final String target;

  const OSActionSpec({required this.type, required this.target});
}

class ElevenLabsGenerationSpec {
  final String? voiceId;
  final String? prompt;
  final double? durationSeconds;

  const ElevenLabsGenerationSpec({
    this.voiceId,
    this.prompt,
    this.durationSeconds,
  });
}

class AIResponse {
  final String responseText;
  final AIIntent intent;
  final VoiceContext voiceContext;
  final OSActionSpec? osAction;
  final ElevenLabsGenerationSpec? generationSpec;

  const AIResponse({
    required this.responseText,
    required this.intent,
    this.voiceContext = VoiceContext.conversational,
    this.osAction,
    this.generationSpec,
  });
}
