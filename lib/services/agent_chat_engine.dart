import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../core/connectivity_guard.dart';
import '../core/exceptions.dart';
import 'settings_service.dart';

/// Result returned by [AgentChatEngine.send].
class AgentChatResult {
  /// MP3 audio chunks from the agent's TTS response, in order.
  final List<Uint8List> audioChunks;

  const AgentChatResult({required this.audioChunks});

  bool get hasAudio => audioChunks.isNotEmpty;

  /// Concatenates all chunks into a single MP3 byte array.
  Uint8List get audioBytes {
    final total = audioChunks.fold<int>(0, (s, c) => s + c.length);
    final out = Uint8List(total);
    var offset = 0;
    for (final c in audioChunks) {
      out.setRange(offset, offset + c.length, c);
      offset += c.length;
    }
    return out;
  }
}

/// Sends audio to the ElevenLabs Conversational Agent over WebSocket and
/// collects the agent's audio response.
///
/// Flow:
///   1. Caller converts user text → PCM via ElevenLabs TTS (outside this class).
///   2. [send] opens a WebSocket session, streams the PCM chunks, then signals
///      end-of-audio.
///   3. Agent processes the audio and streams back MP3 TTS chunks.
///   4. Returns [AgentChatResult] with all audio chunks collected.
class AgentChatEngine {
  final SettingsService _settingsService;
  final ConnectivityGuard _connectivityGuard;

  AgentChatEngine({
    SettingsService? settingsService,
    ConnectivityGuard? connectivityGuard,
  }) : _settingsService = settingsService ?? SettingsService.instance,
       _connectivityGuard = connectivityGuard ?? ConnectivityGuard();

  /// Sends [pcmAudioBytes] (16kHz, mono, 16-bit PCM) to the agent and returns
  /// the agent's audio response.
  Future<AgentChatResult> send(Uint8List pcmAudioBytes) async {
    if (!await _connectivityGuard.isConnected()) {
      throw const OfflineException('No internet connection');
    }

    final settings = await _settingsService.loadSettings();
    final apiKey = settings.elevenLabsApiKey;
    final agentId = settings.agentId;

    if (agentId.isEmpty) {
      throw AgentSessionError(
        'No Agent ID configured. Please set it in Settings.',
      );
    }

    WebSocket socket;
    try {
      socket = await WebSocket.connect(
        'wss://api.elevenlabs.io/v1/convai/conversation?agent_id=$agentId',
        headers: {'xi-api-key': apiKey},
      );
    } catch (e) {
      throw AgentSessionError('Failed to connect to agent: $e');
    }

    final audioChunks = <Uint8List>[];
    final completer = Completer<AgentChatResult>();
    bool agentTurnComplete = false;
    bool audioSent = false;

    void sendAudio() {
      if (audioSent || socket.readyState != WebSocket.open) return;
      audioSent = true;

      // Send PCM in 4096-byte chunks as base64-encoded user_audio_chunk events.
      const chunkSize = 4096;
      for (var i = 0; i < pcmAudioBytes.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, pcmAudioBytes.length);
        final chunk = pcmAudioBytes.sublist(i, end);
        socket.add(jsonEncode({'user_audio_chunk': base64Encode(chunk)}));
      }
    }

    socket.listen(
      (dynamic raw) {
        if (raw is! String) return;
        // ignore: avoid_print
        print('[Kevin Agent] $raw');
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          final type = json['type'] as String?;

          switch (type) {
            case 'conversation_initiation_metadata':
            case 'session_started':
              sendAudio();

            case 'audio':
              final b64 = json['audio_event']?['audio_base_64'] as String?;
              if (b64 != null && b64.isNotEmpty) {
                audioChunks.add(base64Decode(b64));
              }

            case 'turn_end':
              agentTurnComplete = true;
              socket.close();

            case 'error':
              final msg = json['error']?['message'] as String? ?? 'Agent error';
              if (!completer.isCompleted) {
                completer.completeError(AgentSessionError(msg));
              }
              socket.close();
          }
        } catch (_) {}
      },
      onDone: () {
        if (!completer.isCompleted) {
          if (agentTurnComplete || audioChunks.isNotEmpty) {
            completer.complete(AgentChatResult(audioChunks: audioChunks));
          } else {
            completer.completeError(
              AgentSessionError('Agent closed without responding.'),
            );
          }
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError(AgentSessionError('WebSocket error: $e'));
        }
      },
      cancelOnError: true,
    );

    // Send initiation data — no overrides, use agent's default config.
    socket.add(jsonEncode({'type': 'conversation_initiation_client_data'}));

    // Fallback: send audio 800ms after connect if initiation event never fires.
    Future.delayed(const Duration(milliseconds: 800), sendAudio);

    return completer.future;
  }
}
