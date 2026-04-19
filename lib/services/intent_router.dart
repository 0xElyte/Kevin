import 'dart:typed_data';

import '../core/models/ai_response.dart';
import '../core/models/os_action.dart';

// ---------------------------------------------------------------------------
// Abstract service interfaces
// These allow the router to be tested without real implementations.
// ---------------------------------------------------------------------------

/// Interface for the OS bridge (Android Intent / Windows Shell).
abstract class IOSBridge {
  Future<OSActionResult> openApp(String appName);
  Future<OSActionResult> navigateToSettings(SettingsTarget target);
}

/// Interface for the ElevenLabs client (STT, TTS, Music, SFX).
abstract class IElevenLabsClient {
  Future<String> transcribe(Uint8List audioBytes);
  Stream<Uint8List> synthesizeSpeech(String text, String voiceId);
  Future<Uint8List> generateMusic(String prompt);
  Future<Uint8List> generateSoundEffect(String prompt);
}

/// Interface for the audio player service.
abstract class IAudioPlayerService {
  Future<void> playStream(Stream<Uint8List> audioStream);
  Future<void> playBytes(Uint8List audioBytes);
  Future<void> stop();
}

// ---------------------------------------------------------------------------
// Routing result types
// ---------------------------------------------------------------------------

/// Discriminated union of possible routing outcomes returned to the UI.
sealed class RouterResult {}

/// The response should be rendered as a text bubble.
class TextResult extends RouterResult {
  final String text;
  TextResult(this.text);
}

/// An OS action was executed; carry the outcome and confirmation text.
class OSActionRouterResult extends RouterResult {
  final OSActionResult actionResult;
  final String confirmationText;
  OSActionRouterResult({
    required this.actionResult,
    required this.confirmationText,
  });
}

/// Audio was generated / synthesised and is ready for playback.
class AudioResult extends RouterResult {
  final Uint8List audioBytes;
  final String responseText;
  AudioResult({required this.audioBytes, required this.responseText});
}

/// TTS streaming was started; the stream is available for the player.
class TTSStreamResult extends RouterResult {
  final Stream<Uint8List> audioStream;
  final String responseText;
  TTSStreamResult({required this.audioStream, required this.responseText});
}

/// An error occurred during routing.
class ErrorResult extends RouterResult {
  final String message;
  final Object? error;
  ErrorResult({required this.message, this.error});
}

// ---------------------------------------------------------------------------
// IntentRouter
// ---------------------------------------------------------------------------

/// Routes an [AIResponse] to the appropriate service based on its [AIIntent].
///
/// Dependencies are injected via the constructor so the router can be tested
/// with mock implementations.
class IntentRouter {
  final IOSBridge? osBridge;
  final IElevenLabsClient? elevenLabsClient;
  final IAudioPlayerService? audioPlayerService;

  /// Default voice ID used when the generation spec does not specify one.
  final String defaultVoiceId;

  IntentRouter({
    this.osBridge,
    this.elevenLabsClient,
    this.audioPlayerService,
    this.defaultVoiceId = '',
  });

  /// Routes [response] to the appropriate service and returns a [RouterResult]
  /// that the UI layer can use to render the correct widget.
  Future<RouterResult> route(AIResponse response) async {
    switch (response.intent) {
      case AIIntent.osAction:
        return _handleOsAction(response);
      case AIIntent.elevenLabsTTS:
        return _handleTTS(response);
      case AIIntent.elevenLabsMusic:
        return _handleMusic(response);
      case AIIntent.elevenLabsSFX:
        return _handleSFX(response);
      case AIIntent.generalQuery:
        return _handleGeneralQuery(response);
    }
  }

  // -------------------------------------------------------------------------
  // Private handlers
  // -------------------------------------------------------------------------

  Future<RouterResult> _handleOsAction(AIResponse response) async {
    final bridge = osBridge;
    if (bridge == null) {
      return ErrorResult(
        message: 'OS Bridge is not available on this platform.',
      );
    }

    final spec = response.osAction;
    if (spec == null) {
      return ErrorResult(
        message: 'OS action intent received but no action spec provided.',
      );
    }

    try {
      OSActionResult result;
      if (spec.type == 'navigate_settings') {
        final target = _parseSettingsTarget(spec.target);
        if (target == null) {
          return ErrorResult(
            message: 'Unknown settings target: ${spec.target}',
          );
        }
        result = await bridge.navigateToSettings(target);
      } else {
        // Default: open_app
        result = await bridge.openApp(spec.target);
      }

      final confirmationText = result.success
          ? response.responseText
          : (result.errorMessage ?? 'The action could not be completed.');

      return OSActionRouterResult(
        actionResult: result,
        confirmationText: confirmationText,
      );
    } catch (e) {
      return ErrorResult(
        message: 'OS action failed: ${e.toString()}',
        error: e,
      );
    }
  }

  Future<RouterResult> _handleTTS(AIResponse response) async {
    final client = elevenLabsClient;
    if (client == null) {
      // Fall back to text if TTS is unavailable.
      return TextResult(response.responseText);
    }

    final spec = response.generationSpec;
    final text = spec?.prompt ?? response.responseText;
    final voiceId = spec?.voiceId ?? defaultVoiceId;

    if (text.isEmpty) {
      return TextResult(response.responseText);
    }

    try {
      final stream = client.synthesizeSpeech(text, voiceId);
      return TTSStreamResult(
        audioStream: stream,
        responseText: response.responseText,
      );
    } catch (e) {
      // Graceful fallback to text on synthesis error.
      return TextResult(response.responseText);
    }
  }

  Future<RouterResult> _handleMusic(AIResponse response) async {
    final client = elevenLabsClient;
    if (client == null) {
      return ErrorResult(message: 'ElevenLabs client is not available.');
    }

    final prompt = response.generationSpec?.prompt ?? response.responseText;

    try {
      final bytes = await client.generateMusic(prompt);
      return AudioResult(
        audioBytes: bytes,
        responseText: response.responseText,
      );
    } catch (e) {
      return ErrorResult(
        message: 'Music generation failed: ${e.toString()}',
        error: e,
      );
    }
  }

  Future<RouterResult> _handleSFX(AIResponse response) async {
    final client = elevenLabsClient;
    if (client == null) {
      return ErrorResult(message: 'ElevenLabs client is not available.');
    }

    final prompt = response.generationSpec?.prompt ?? response.responseText;

    try {
      final bytes = await client.generateSoundEffect(prompt);
      return AudioResult(
        audioBytes: bytes,
        responseText: response.responseText,
      );
    } catch (e) {
      return ErrorResult(
        message: 'Sound effect generation failed: ${e.toString()}',
        error: e,
      );
    }
  }

  Future<RouterResult> _handleGeneralQuery(AIResponse response) async {
    // General queries are rendered as text; TTS is applied by the UI layer
    // based on the active ResponseMode.
    return TextResult(response.responseText);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  SettingsTarget? _parseSettingsTarget(String target) {
    switch (target.toLowerCase()) {
      case 'wifi':
        return SettingsTarget.wifi;
      case 'bluetooth':
        return SettingsTarget.bluetooth;
      case 'display':
        return SettingsTarget.display;
      case 'sound':
        return SettingsTarget.sound;
      case 'battery':
        return SettingsTarget.battery;
      case 'storage':
        return SettingsTarget.storage;
      default:
        return null;
    }
  }
}
