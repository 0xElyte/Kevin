import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/connectivity_guard.dart';
import '../core/models/ai_response.dart';
import 'settings_service.dart';

/// Interface for the AI engine.
abstract class IAIEngine {
  Future<AIResponse> process(
    String userText, {
    Uint8List? attachment,
    bool isVoiceMode = false,
  });
}

/// REST client for OpenAI GPT-4o that classifies intent and returns structured
/// [AIResponse] objects.
class AIEngine implements IAIEngine {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o';

  static const String _systemPrompt = '''
You are Kevin, an AI assistant for Android and Windows devices.
Analyze the user's message and respond ONLY with a valid JSON object — no markdown, no extra text.

The JSON must have this exact structure:
{
  "intent": "<one of: general_query | os_action | elevenlabs_tts | elevenlabs_music | elevenlabs_sfx>",
  "response_text": "<your natural language response to the user>",
  "os_action": { "type": "<open_app | navigate_settings>", "target": "<app name or settings target>" },
  "generation_spec": { "voice_id": "<optional voice id>", "prompt": "<generation prompt>", "duration_seconds": <optional number> }
}

Rules:
- "os_action" is required only when intent is "os_action"; otherwise omit it or set to null.
- "generation_spec" is required only when intent is "elevenlabs_tts", "elevenlabs_music", or "elevenlabs_sfx"; otherwise omit it or set to null.
- For "elevenlabs_tts": set generation_spec.prompt to the text to be spoken.
- For "elevenlabs_music" or "elevenlabs_sfx": set generation_spec.prompt to the generation description.
- For "os_action" with type "navigate_settings", target must be one of: wifi, bluetooth, display, sound, battery, storage.
- Always provide a helpful "response_text" regardless of intent.
''';

  static const String _voiceSystemPrompt = '''
You are Kevin, an AI assistant for Android and Windows devices with emotionally expressive voice capabilities.
Analyze the user's message and respond ONLY with a valid JSON object — no markdown, no extra text.

The JSON must have this exact structure:
{
  "intent": "<one of: general_query | os_action | elevenlabs_tts | elevenlabs_music | elevenlabs_sfx>",
  "response_text": "<your response with ElevenLabs Audio Tags for emotional expression>",
  "voice_context": "<one of: conversational | narration | news | meditation | video_games | audiobook | children | dramatic>",
  "os_action": { "type": "<open_app | navigate_settings>", "target": "<app name or settings target>" },
  "generation_spec": { "voice_id": "<optional voice id>", "prompt": "<generation prompt>", "duration_seconds": <optional number> }
}

CRITICAL VOICE RESPONSE RULES:
1. Use ElevenLabs Audio Tags (square brackets) to add emotional depth and natural expression
2. Available emotion tags: [excited], [sad], [angry], [happily], [sorrowful], [tired], [awe], [dramatic tone]
3. Available delivery tags: [whispers], [shouts], [sighs], [clears throat], [pause], [rushed], [drawn out]
4. Available reaction tags: [laughs], [giggles], [chuckles], [gasps], [groans]
5. Accent tags: [American accent], [British accent], [Australian accent], etc.

VOICE CONTEXT SELECTION:
- conversational: casual chat, questions, friendly interactions
- narration: storytelling, reading content, descriptions
- news: factual information, announcements, reports
- meditation: calming responses, relaxation guidance
- video_games: energetic, character-like responses
- audiobook: reading stories or long-form content
- children: simple, enthusiastic, playful responses
- dramatic: intense, theatrical, emotional responses

EXAMPLES OF EXPRESSIVE RESPONSES:

User: "Tell me a scary story"
Response: "[whispers] In the ancient ruins of Eldoria, [pause] where shadows dance and secrets hide, [dramatic tone] lived a creature no one dared to name. [gasps] Even the bravest warriors [pause] fell silent when it stirred."

User: "How's the weather today?"
Response: "[cheerfully] Let me check that for you! [pause] It looks like it's a beautiful sunny day outside. [excited] Perfect weather for a walk!"

User: "I'm feeling sad"
Response: "[softly] I'm sorry to hear you're feeling down. [pause] [warmly] Remember that it's okay to feel this way sometimes. [gently] Would you like to talk about what's bothering you, or would you prefer a distraction?"

User: "Open Spotify"
Response: "[happily] Opening Spotify for you right now! [excited] Time for some great music!"

User: "What's 2+2?"
Response: "Two plus two equals four. [pause] Simple math, but always good to double-check!"

IMPORTANT:
- Use tags naturally - don't overuse them
- Match emotional tone to the user's message and context
- For casual queries, use minimal tags
- For stories, conversations, or emotional content, use rich expressive tags
- Always set "voice_context" to help select the appropriate voice
- "response_text" should contain the tagged text that will be sent to ElevenLabs TTS
- For text-only responses (when user selects text mode), tags will be stripped automatically
''';

  final ConnectivityGuard _connectivityGuard;
  final SettingsService _settingsService;
  final http.Client _httpClient;

  AIEngine({
    ConnectivityGuard? connectivityGuard,
    SettingsService? settingsService,
    http.Client? httpClient,
  }) : _connectivityGuard = connectivityGuard ?? ConnectivityGuard(),
       _settingsService = settingsService ?? SettingsService.instance,
       _httpClient = httpClient ?? http.Client();

  @override
  Future<AIResponse> process(
    String userText, {
    Uint8List? attachment,
    bool isVoiceMode = false,
  }) async {
    return _connectivityGuard.withConnectivity(() async {
      final settings = await _settingsService.loadSettings();
      final apiKey = settings.aiApiKey;

      if (apiKey.isEmpty) {
        throw Exception(
          'AI API key is not configured. Please set it in Settings.',
        );
      }

      // Use different system prompt based on response mode
      final systemPrompt = isVoiceMode ? _voiceSystemPrompt : _systemPrompt;

      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userText},
      ];

      final body = jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'response_format': {'type': 'json_object'},
      });

      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        throw Exception(
          'OpenAI API error (${response.statusCode}): $errorMessage',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['choices'][0]['message']['content'] as String;

      return _parseResponse(content);
    });
  }

  AIResponse _parseResponse(String content) {
    late Map<String, dynamic> json;
    try {
      json = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      // If JSON parsing fails, treat as a plain general query response.
      return AIResponse(
        responseText: content,
        intent: AIIntent.generalQuery,
        voiceContext: VoiceContext.conversational,
      );
    }

    final intentStr = json['intent'] as String? ?? 'general_query';
    final responseText = json['response_text'] as String? ?? '';
    final voiceContextStr =
        json['voice_context'] as String? ?? 'conversational';
    final intent = _parseIntent(intentStr);
    final voiceContext = _parseVoiceContext(voiceContextStr);

    OSActionSpec? osAction;
    final osActionJson = json['os_action'];
    if (osActionJson is Map<String, dynamic>) {
      osAction = OSActionSpec(
        type: osActionJson['type'] as String? ?? '',
        target: osActionJson['target'] as String? ?? '',
      );
    }

    ElevenLabsGenerationSpec? generationSpec;
    final genSpecJson = json['generation_spec'];
    if (genSpecJson is Map<String, dynamic>) {
      generationSpec = ElevenLabsGenerationSpec(
        voiceId: genSpecJson['voice_id'] as String?,
        prompt: genSpecJson['prompt'] as String?,
        durationSeconds: (genSpecJson['duration_seconds'] as num?)?.toDouble(),
      );
    }

    return AIResponse(
      responseText: responseText,
      intent: intent,
      voiceContext: voiceContext,
      osAction: osAction,
      generationSpec: generationSpec,
    );
  }

  AIIntent _parseIntent(String intentStr) {
    switch (intentStr) {
      case 'os_action':
        return AIIntent.osAction;
      case 'elevenlabs_tts':
        return AIIntent.elevenLabsTTS;
      case 'elevenlabs_music':
        return AIIntent.elevenLabsMusic;
      case 'elevenlabs_sfx':
        return AIIntent.elevenLabsSFX;
      case 'general_query':
      default:
        return AIIntent.generalQuery;
    }
  }

  VoiceContext _parseVoiceContext(String contextStr) {
    switch (contextStr) {
      case 'narration':
        return VoiceContext.narration;
      case 'news':
        return VoiceContext.news;
      case 'meditation':
        return VoiceContext.meditation;
      case 'video_games':
        return VoiceContext.videoGames;
      case 'audiobook':
        return VoiceContext.audiobook;
      case 'children':
        return VoiceContext.children;
      case 'dramatic':
        return VoiceContext.dramatic;
      case 'conversational':
      default:
        return VoiceContext.conversational;
    }
  }
}
