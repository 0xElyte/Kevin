import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_kevin/core/connectivity_guard.dart';
import 'package:project_kevin/core/exceptions.dart';
import 'package:project_kevin/services/elevenlabs_client.dart';
import 'package:project_kevin/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [ConnectivityGuard] that always considers the device online.
class _AlwaysOnlineConnectivityGuard extends ConnectivityGuard {
  @override
  Future<T> withConnectivity<T>(Future<T> Function() request) => request();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'eleven_labs_api_key': 'test-api-key',
    });
    SettingsService.resetInstance();
  });

  group('ElevenLabsClient - transcribe (batch STT)', () {
    test('transcribe returns transcript on success', () async {
      final audioBytes = Uint8List.fromList([1, 2, 3, 4]);
      final responseBody = jsonEncode({'text': 'Hello world'});

      final mockClient = MockClient((request) async {
        return http.Response(responseBody, 200);
      });

      final client = ElevenLabsClient(
        connectivityGuard: _AlwaysOnlineConnectivityGuard(),
        httpClient: mockClient,
      );

      final result = await client.transcribe(audioBytes);

      expect(result, 'Hello world');
    });

    test('transcribe throws STTTranscriptionError on non-200 status', () async {
      final audioBytes = Uint8List.fromList([1, 2, 3, 4]);

      final mockClient = MockClient((request) async {
        return http.Response('Error message', 400);
      });

      final client = ElevenLabsClient(
        connectivityGuard: _AlwaysOnlineConnectivityGuard(),
        httpClient: mockClient,
      );

      expect(
        () => client.transcribe(audioBytes),
        throwsA(isA<STTTranscriptionError>()),
      );
    });

    test(
      'transcribe throws STTTranscriptionError when text field missing',
      () async {
        final audioBytes = Uint8List.fromList([1, 2, 3, 4]);
        final responseBody = jsonEncode({'no_text_field': 'oops'});

        final mockClient = MockClient((request) async {
          return http.Response(responseBody, 200);
        });

        final client = ElevenLabsClient(
          connectivityGuard: _AlwaysOnlineConnectivityGuard(),
          httpClient: mockClient,
        );

        expect(
          () => client.transcribe(audioBytes),
          throwsA(isA<STTTranscriptionError>()),
        );
      },
    );
  });

  group('ElevenLabsClient - transcribeRealtime (WebSocket STT)', () {
    // Note: Testing WebSocket connections requires more complex mocking.
    // These tests verify the method exists and handles basic error cases.
    // Full integration testing would require a mock WebSocket server.

    test('transcribeRealtime method exists and accepts audio stream', () {
      final client = ElevenLabsClient(
        connectivityGuard: _AlwaysOnlineConnectivityGuard(),
        httpClient: MockClient((request) async => http.Response('', 200)),
      );

      // Verify the method signature exists
      expect(
        client.transcribeRealtime,
        isA<Future<String> Function(Stream<Uint8List>)>(),
      );
    });

    // Skip WebSocket connection test as it requires actual network connection
    // or complex WebSocket mocking which is beyond the scope of unit tests.
    // Integration tests should cover the full WebSocket flow.
  });

  group('ElevenLabsClient - generateMusic', () {
    test(
      'generateMusic returns audio bytes when audio_url is immediately available',
      () async {
        final mockAudioBytes = Uint8List.fromList([10, 20, 30, 40]);

        final mockClient = MockClient((request) async {
          if (request.url.path == '/v1/music') {
            // Initial request returns audio_url immediately
            final responseBody = jsonEncode({
              'generation_id': 'gen-123',
              'audio_url': 'https://api.elevenlabs.io/audio/gen-123.mp3',
            });
            return http.Response(responseBody, 200);
          } else if (request.url.path.contains('/audio/')) {
            // Audio download
            return http.Response.bytes(mockAudioBytes, 200);
          }
          return http.Response('Not found', 404);
        });

        final client = ElevenLabsClient(
          connectivityGuard: _AlwaysOnlineConnectivityGuard(),
          httpClient: mockClient,
        );

        final result = await client.generateMusic('Heavy Metal BGM');

        expect(result, mockAudioBytes);
      },
    );

    test(
      'generateMusic polls and returns audio bytes when generation is async',
      () async {
        final mockAudioBytes = Uint8List.fromList([10, 20, 30, 40]);
        int pollCount = 0;

        final mockClient = MockClient((request) async {
          if (request.url.path == '/v1/music') {
            // Initial request returns generation_id without audio_url
            final responseBody = jsonEncode({'generation_id': 'gen-456'});
            return http.Response(responseBody, 200);
          } else if (request.url.path == '/v1/music/gen-456') {
            // Status polling
            pollCount++;
            if (pollCount < 3) {
              // First 2 polls: still processing
              final responseBody = jsonEncode({
                'status': 'processing',
                'generation_id': 'gen-456',
              });
              return http.Response(responseBody, 200);
            } else {
              // Third poll: complete
              final responseBody = jsonEncode({
                'status': 'complete',
                'generation_id': 'gen-456',
                'audio_url': 'https://api.elevenlabs.io/audio/gen-456.mp3',
              });
              return http.Response(responseBody, 200);
            }
          } else if (request.url.path.contains('/audio/')) {
            // Audio download
            return http.Response.bytes(mockAudioBytes, 200);
          }
          return http.Response('Not found', 404);
        });

        final client = ElevenLabsClient(
          connectivityGuard: _AlwaysOnlineConnectivityGuard(),
          httpClient: mockClient,
        );

        final result = await client.generateMusic('Epic orchestral music');

        expect(result, mockAudioBytes);
        expect(pollCount, 3);
      },
    );

    test(
      'generateMusic throws MusicGenerationError on non-200 initial response',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Bad request', 400);
        });

        final client = ElevenLabsClient(
          connectivityGuard: _AlwaysOnlineConnectivityGuard(),
          httpClient: mockClient,
        );

        expect(
          () => client.generateMusic('test prompt'),
          throwsA(isA<MusicGenerationError>()),
        );
      },
    );

    test(
      'generateMusic throws MusicGenerationError when generation_id is missing',
      () async {
        final mockClient = MockClient((request) async {
          final responseBody = jsonEncode({'no_generation_id': 'oops'});
          return http.Response(responseBody, 200);
        });

        final client = ElevenLabsClient(
          connectivityGuard: _AlwaysOnlineConnectivityGuard(),
          httpClient: mockClient,
        );

        expect(
          () => client.generateMusic('test prompt'),
          throwsA(isA<MusicGenerationError>()),
        );
      },
    );

    test(
      'generateMusic throws MusicGenerationError when status is failed',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/v1/music') {
            final responseBody = jsonEncode({'generation_id': 'gen-789'});
            return http.Response(responseBody, 200);
          } else if (request.url.path == '/v1/music/gen-789') {
            final responseBody = jsonEncode({
              'status': 'failed',
              'error': 'Generation failed due to invalid prompt',
            });
            return http.Response(responseBody, 200);
          }
          return http.Response('Not found', 404);
        });

        final client = ElevenLabsClient(
          connectivityGuard: _AlwaysOnlineConnectivityGuard(),
          httpClient: mockClient,
        );

        expect(
          () => client.generateMusic('test prompt'),
          throwsA(isA<MusicGenerationError>()),
        );
      },
    );
  });

  group('ElevenLabsClient - generateSoundEffect', () {
    test('generateSoundEffect returns audio bytes on success', () async {
      final mockAudioBytes = Uint8List.fromList([50, 60, 70, 80]);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/v1/sound-generation') {
          // Sound effects API returns binary MP3 directly
          return http.Response.bytes(mockAudioBytes, 200);
        }
        return http.Response('Not found', 404);
      });

      final client = ElevenLabsClient(
        connectivityGuard: _AlwaysOnlineConnectivityGuard(),
        httpClient: mockClient,
      );

      final result = await client.generateSoundEffect('thunderstorm');

      expect(result, mockAudioBytes);
    });

    test(
      'generateSoundEffect throws SoundEffectGenerationError on non-200 response',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Bad request', 400);
        });

        final client = ElevenLabsClient(
          connectivityGuard: _AlwaysOnlineConnectivityGuard(),
          httpClient: mockClient,
        );

        expect(
          () => client.generateSoundEffect('test prompt'),
          throwsA(isA<SoundEffectGenerationError>()),
        );
      },
    );

    test(
      'generateSoundEffect sends correct request body with text and duration',
      () async {
        final mockAudioBytes = Uint8List.fromList([90, 100, 110]);
        String? capturedBody;

        final mockClient = MockClient((request) async {
          if (request.url.path == '/v1/sound-generation') {
            capturedBody = request.body;
            return http.Response.bytes(mockAudioBytes, 200);
          }
          return http.Response('Not found', 404);
        });

        final client = ElevenLabsClient(
          connectivityGuard: _AlwaysOnlineConnectivityGuard(),
          httpClient: mockClient,
        );

        await client.generateSoundEffect('explosion sound');

        expect(capturedBody, isNotNull);
        final bodyJson = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(bodyJson['text'], 'explosion sound');
        expect(bodyJson['duration_seconds'], 10);
      },
    );
  });

  group('ElevenLabsClient - unimplemented methods', () {
    // This group is now empty since generateSoundEffect is implemented
    // Keeping the group for future unimplemented methods
  });
}
