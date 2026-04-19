enum AIIntent {
  generalQuery,
  osAction,
  elevenLabsTTS,
  elevenLabsMusic,
  elevenLabsSFX,

  /// Start a live ElevenLabs Conversational Agent session (full-duplex voice).
  elevenLabsAgent,

  /// Place an outbound phone call via ElevenLabs + Twilio.
  elevenLabsCall,

  /// Generate a voice clip and share it via the OS share sheet.
  elevenLabsVoiceShare,
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
