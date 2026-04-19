import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/connectivity_guard.dart';
import '../core/exceptions.dart';
import 'intent_router.dart';
import 'settings_service.dart';

/// Concrete implementation of [IElevenLabsClient] that calls the ElevenLabs REST API.
class ElevenLabsClient implements IElevenLabsClient {
  static const String _baseUrl = 'https://api.elevenlabs.io';

  final SettingsService _settingsService;
  final ConnectivityGuard _connectivityGuard;
  final http.Client _httpClient;

  ElevenLabsClient({
    SettingsService? settingsService,
    ConnectivityGuard? connectivityGuard,
    http.Client? httpClient,
  }) : _settingsService = settingsService ?? SettingsService.instance,
       _connectivityGuard = connectivityGuard ?? ConnectivityGuard(),
       _httpClient = httpClient ?? http.Client();

  // ---------------------------------------------------------------------------
  // STT — Scribe v2 (batch)
  // ---------------------------------------------------------------------------

  /// Transcribes [audioBytes] using the ElevenLabs Scribe v2 batch endpoint.
  ///
  /// Throws [STTTranscriptionError] if the API returns an error response.
  /// Throws [OfflineException] if there is no network connectivity.
  /// Throws [TimeoutException] if the request exceeds 10 seconds.
  @override
  Future<String> transcribe(Uint8List audioBytes) async {
    return _connectivityGuard.withConnectivity(() async {
      final settings = await _settingsService.loadSettings();
      final apiKey = settings.elevenLabsApiKey;

      final uri = Uri.parse('$_baseUrl/v1/speech-to-text');
      final request = http.MultipartRequest('POST', uri)
        ..headers['xi-api-key'] = apiKey
        ..fields['model_id'] = 'scribe_v2'
        ..files.add(
          http.MultipartFile.fromBytes(
            'audio',
            audioBytes,
            filename: 'audio.wav',
          ),
        );

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw STTTranscriptionError(
          'STT request failed with status ${response.statusCode}: ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final text = json['text'] as String?;
      if (text == null) {
        throw const STTTranscriptionError(
          'STT response did not contain a "text" field.',
        );
      }

      return text;
    });
  }

  // ---------------------------------------------------------------------------
  // STT — Scribe v2 Realtime (WebSocket)
  // ---------------------------------------------------------------------------

  /// Transcribes a live audio stream using the ElevenLabs Scribe v2 Realtime
  /// WebSocket endpoint.
  ///
  /// [audioStream] should emit raw PCM audio chunks. Each chunk is sent as a
  /// binary WebSocket frame. When the stream ends, a JSON close message is
  /// sent to signal end-of-audio, and the method waits for the final
  /// transcript from the server.
  ///
  /// Returns the final transcript string.
  ///
  /// Throws [STTTranscriptionError] if the connection fails or the server
  /// returns an error.
  /// Throws [OfflineException] if there is no network connectivity.
  Future<String> transcribeRealtime(Stream<Uint8List> audioStream) async {
    return _connectivityGuard.withConnectivity(() async {
      final settings = await _settingsService.loadSettings();
      final apiKey = settings.elevenLabsApiKey;

      WebSocket? socket;
      try {
        socket = await WebSocket.connect(
          'wss://api.elevenlabs.io/v1/speech-to-text/stream',
          headers: {'xi-api-key': apiKey},
        );
      } catch (e) {
        throw STTTranscriptionError(
          'Failed to connect to STT realtime endpoint: $e',
        );
      }

      String finalTranscript = '';
      final completer = Completer<String>();

      // Listen for messages from the server.
      final subscription = socket.listen(
        (dynamic message) {
          if (message is String) {
            try {
              final json = jsonDecode(message) as Map<String, dynamic>;
              final type = json['type'] as String?;
              if (type == 'transcript') {
                final text = json['text'] as String? ?? '';
                final isFinal = json['is_final'] as bool? ?? false;
                if (isFinal && text.isNotEmpty) {
                  finalTranscript = text;
                }
              } else if (type == 'error') {
                final errorMsg =
                    json['message'] as String? ?? 'Unknown STT error';
                if (!completer.isCompleted) {
                  completer.completeError(
                    STTTranscriptionError('STT realtime error: $errorMsg'),
                  );
                }
              }
            } catch (_) {
              // Ignore malformed JSON messages.
            }
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(finalTranscript);
          }
        },
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(
              STTTranscriptionError('STT realtime WebSocket error: $error'),
            );
          }
        },
        cancelOnError: true,
      );

      // Stream audio chunks as binary frames.
      try {
        await for (final chunk in audioStream) {
          if (socket.readyState == WebSocket.open) {
            socket.add(chunk);
          }
        }
      } catch (e) {
        await subscription.cancel();
        await socket.close();
        throw STTTranscriptionError('Error streaming audio: $e');
      }

      // Signal end of audio to the server.
      if (socket.readyState == WebSocket.open) {
        socket.add(jsonEncode({'type': 'end_of_audio'}));
        await socket.close();
      }

      try {
        return await completer.future;
      } catch (e) {
        if (e is STTTranscriptionError) rethrow;
        throw STTTranscriptionError('STT realtime failed: $e');
      }
    });
  }

  // ---------------------------------------------------------------------------
  // TTS — Streaming
  // ---------------------------------------------------------------------------

  /// Synthesizes speech from [text] using the specified [voiceId] via the
  /// ElevenLabs TTS streaming endpoint.
  ///
  /// Returns a stream of MP3 audio chunks that can be piped directly to an
  /// audio player for low-latency playback.
  ///
  /// Throws [TTSSynthesisError] if the API returns an error response.
  /// Throws [OfflineException] if there is no network connectivity.
  /// Throws [TimeoutException] if the request exceeds 10 seconds.
  @override
  Stream<Uint8List> synthesizeSpeech(String text, String voiceId) async* {
    final settings = await _settingsService.loadSettings();
    final apiKey = settings.elevenLabsApiKey;

    final uri = Uri.parse('$_baseUrl/v1/text-to-speech/$voiceId/stream');

    try {
      final request = http.Request('POST', uri)
        ..headers['xi-api-key'] = apiKey
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'text': text,
          'model_id': 'eleven_v3', // Use eleven_v3 for audio tag support
          'language_code': 'en',
        });

      final response = await _connectivityGuard.withConnectivity(() async {
        return await _httpClient.send(request);
      });

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw TTSSynthesisError(
          'TTS request failed with status ${response.statusCode}: $errorBody',
        );
      }

      // Stream the audio chunks as they arrive
      await for (final chunk in response.stream) {
        yield Uint8List.fromList(chunk);
      }
    } catch (e) {
      if (e is TTSSynthesisError) rethrow;
      if (e is OfflineException) rethrow;
      if (e is TimeoutException) rethrow;
      throw TTSSynthesisError('TTS synthesis failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Music — Eleven Music API
  // ---------------------------------------------------------------------------

  /// Generates music from a natural-language [prompt] using the ElevenLabs
  /// Music API.
  ///
  /// This is an asynchronous operation: the API returns a generation ID, and
  /// we poll the status endpoint until the generation is complete, then
  /// download the MP3 audio bytes.
  ///
  /// Throws [MusicGenerationError] if the API returns an error response or
  /// if polling times out.
  /// Throws [OfflineException] if there is no network connectivity.
  /// Throws [TimeoutException] if the request exceeds 10 seconds.
  @override
  Future<Uint8List> generateMusic(String prompt) async {
    return _connectivityGuard.withConnectivity(() async {
      final settings = await _settingsService.loadSettings();
      final apiKey = settings.elevenLabsApiKey;

      // Step 1: Initiate music generation
      final uri = Uri.parse('$_baseUrl/v1/music');
      final response = await _httpClient.post(
        uri,
        headers: {'xi-api-key': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt, 'output_format': 'mp3_44100_128'}),
      );

      if (response.statusCode != 200) {
        throw MusicGenerationError(
          'Music generation request failed with status ${response.statusCode}: ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final generationId = json['generation_id'] as String?;
      final audioUrl = json['audio_url'] as String?;

      if (generationId == null) {
        throw const MusicGenerationError(
          'Music generation response did not contain a "generation_id" field.',
        );
      }

      // Step 2: Poll for completion
      // If audio_url is already present, the generation completed synchronously
      if (audioUrl != null && audioUrl.isNotEmpty) {
        return await _downloadAudio(audioUrl, apiKey);
      }

      // Otherwise, poll the status endpoint
      return await _pollMusicGeneration(generationId, apiKey);
    });
  }

  /// Polls the music generation status endpoint until the generation is
  /// complete, then downloads and returns the MP3 audio bytes.
  Future<Uint8List> _pollMusicGeneration(
    String generationId,
    String apiKey,
  ) async {
    const maxAttempts = 60; // Poll for up to 60 seconds (1 attempt per second)
    const pollInterval = Duration(seconds: 1);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);

      final statusUri = Uri.parse('$_baseUrl/v1/music/$generationId');
      final statusResponse = await _httpClient.get(
        statusUri,
        headers: {'xi-api-key': apiKey},
      );

      if (statusResponse.statusCode != 200) {
        throw MusicGenerationError(
          'Music generation status check failed with status ${statusResponse.statusCode}: ${statusResponse.body}',
        );
      }

      final statusJson =
          jsonDecode(statusResponse.body) as Map<String, dynamic>;
      final status = statusJson['status'] as String?;
      final audioUrl = statusJson['audio_url'] as String?;

      if (status == 'complete' && audioUrl != null && audioUrl.isNotEmpty) {
        return await _downloadAudio(audioUrl, apiKey);
      } else if (status == 'failed') {
        final errorMessage = statusJson['error'] as String? ?? 'Unknown error';
        throw MusicGenerationError('Music generation failed: $errorMessage');
      }

      // Status is still 'pending' or 'processing', continue polling
    }

    throw const MusicGenerationError(
      'Music generation timed out after 60 seconds.',
    );
  }

  /// Downloads audio from the given [audioUrl] and returns the MP3 bytes.
  Future<Uint8List> _downloadAudio(String audioUrl, String apiKey) async {
    final uri = Uri.parse(audioUrl);
    final response = await _httpClient.get(
      uri,
      headers: {'xi-api-key': apiKey},
    );

    if (response.statusCode != 200) {
      throw MusicGenerationError(
        'Audio download failed with status ${response.statusCode}',
      );
    }

    return response.bodyBytes;
  }

  // ---------------------------------------------------------------------------
  // SFX — Sound Effects Generation
  // ---------------------------------------------------------------------------

  /// Generates a sound effect from a natural-language [prompt] using the
  /// ElevenLabs Sound Effects API.
  ///
  /// Returns the generated MP3 audio bytes synchronously.
  ///
  /// Throws [SoundEffectGenerationError] if the API returns an error response.
  /// Throws [OfflineException] if there is no network connectivity.
  /// Throws [TimeoutException] if the request exceeds 10 seconds.
  @override
  Future<Uint8List> generateSoundEffect(String prompt) async {
    return _connectivityGuard.withConnectivity(() async {
      final settings = await _settingsService.loadSettings();
      final apiKey = settings.elevenLabsApiKey;

      final uri = Uri.parse('$_baseUrl/v1/sound-generation');
      final response = await _httpClient.post(
        uri,
        headers: {'xi-api-key': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({'text': prompt, 'duration_seconds': 10}),
      );

      if (response.statusCode != 200) {
        throw SoundEffectGenerationError(
          'Sound effect generation request failed with status ${response.statusCode}: ${response.body}',
        );
      }

      // The API returns binary MP3 audio directly
      return response.bodyBytes;
    });
  }
}
