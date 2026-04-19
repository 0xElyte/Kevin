enum ResponseMode { voice, text }

class AppSettings {
  final ResponseMode responseMode;
  final bool wakeWordEnabled;
  final double wakeWordSensitivity;
  final String elevenLabsApiKey;
  final String aiApiKey;
  final String ttsVoiceId;
  final String picovoiceApiKey;

  /// ElevenLabs Conversational Agent ID (from the ElevenLabs dashboard).
  final String agentId;

  /// ElevenLabs-linked Twilio phone number ID for outbound calls.
  final String twilioPhoneNumberId;

  const AppSettings({
    required this.responseMode,
    required this.wakeWordEnabled,
    required this.wakeWordSensitivity,
    required this.elevenLabsApiKey,
    required this.aiApiKey,
    required this.ttsVoiceId,
    this.picovoiceApiKey = '',
    this.agentId = '',
    this.twilioPhoneNumberId = '',
  });

  AppSettings copyWith({
    ResponseMode? responseMode,
    bool? wakeWordEnabled,
    double? wakeWordSensitivity,
    String? elevenLabsApiKey,
    String? aiApiKey,
    String? ttsVoiceId,
    String? picovoiceApiKey,
    String? agentId,
    String? twilioPhoneNumberId,
  }) {
    return AppSettings(
      responseMode: responseMode ?? this.responseMode,
      wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
      wakeWordSensitivity: wakeWordSensitivity ?? this.wakeWordSensitivity,
      elevenLabsApiKey: elevenLabsApiKey ?? this.elevenLabsApiKey,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      ttsVoiceId: ttsVoiceId ?? this.ttsVoiceId,
      picovoiceApiKey: picovoiceApiKey ?? this.picovoiceApiKey,
      agentId: agentId ?? this.agentId,
      twilioPhoneNumberId: twilioPhoneNumberId ?? this.twilioPhoneNumberId,
    );
  }
}
