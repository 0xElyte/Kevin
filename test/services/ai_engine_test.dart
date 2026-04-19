import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_kevin/core/connectivity_guard.dart';
import 'package:project_kevin/core/models/ai_response.dart';
import 'package:project_kevin/services/ai_engine.dart';
import 'package:project_kevin/services/settings_service.dart';

/// A [ConnectivityGuard] that always considers the device online.
class _AlwaysOnlineConnectivityGuard extends ConnectivityGuard {
  @override
  Future<T> withConnectivity<T>(Future<T> Function() request) => request();
}

/// Builds a mock OpenAI response wrapping [content] as the assistant message.
http.Response _mockOpenAIResponse(Map<String, dynamic> content) {
  final body = jsonEncode({
    'choices': [
      {
        'message': {'role': 'assistant', 'content': jsonEncode(content)},
      },
    ],
  });
  return http.Response(
    body,
    200,
    headers: {'content-type': 'application/json'},
  );
}

/// Creates an [AIEngine] with a mock HTTP client that always returns [response].
AIEngine _engineWith(http.Response response) {
  final mockClient = MockClient((_) async => response);
  return AIEngine(
    connectivityGuard: _AlwaysOnlineConnectivityGuard(),
    httpClient: mockClient,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'ai_api_key': 'test-key'});
    SettingsService.resetInstance();
  });

  group('AIEngine intent classification', () {
    test('general_query intent is parsed correctly', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({
          'intent': 'general_query',
          'response_text': 'The capital of France is Paris.',
        }),
      );

      final result = await engine.process('What is the capital of France?');

      expect(result.intent, AIIntent.generalQuery);
      expect(result.responseText, 'The capital of France is Paris.');
      expect(result.osAction, isNull);
      expect(result.generationSpec, isNull);
    });

    test('os_action intent is parsed with OSActionSpec', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({
          'intent': 'os_action',
          'response_text': 'Opening Spotify for you.',
          'os_action': {'type': 'open_app', 'target': 'Spotify'},
        }),
      );

      final result = await engine.process('Open Spotify');

      expect(result.intent, AIIntent.osAction);
      expect(result.osAction, isNotNull);
      expect(result.osAction!.type, 'open_app');
      expect(result.osAction!.target, 'Spotify');
    });

    test('os_action navigate_settings is parsed correctly', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({
          'intent': 'os_action',
          'response_text': 'Opening Wi-Fi settings.',
          'os_action': {'type': 'navigate_settings', 'target': 'wifi'},
        }),
      );

      final result = await engine.process('Open Wi-Fi settings');

      expect(result.intent, AIIntent.osAction);
      expect(result.osAction!.type, 'navigate_settings');
      expect(result.osAction!.target, 'wifi');
    });

    test('elevenlabs_tts intent is parsed with generation_spec', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({
          'intent': 'elevenlabs_tts',
          'response_text': 'Reading the text in a dramatic voice.',
          'generation_spec': {'prompt': 'Hello world', 'voice_id': 'voice-123'},
        }),
      );

      final result = await engine.process(
        'Read "Hello world" in a dramatic voice',
      );

      expect(result.intent, AIIntent.elevenLabsTTS);
      expect(result.generationSpec, isNotNull);
      expect(result.generationSpec!.prompt, 'Hello world');
      expect(result.generationSpec!.voiceId, 'voice-123');
    });

    test('elevenlabs_music intent is parsed with generation_spec', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({
          'intent': 'elevenlabs_music',
          'response_text': 'Generating heavy metal BGM.',
          'generation_spec': {'prompt': 'Heavy Metal BGM for an Action Game'},
        }),
      );

      final result = await engine.process(
        'Generate a Heavy Metal BGM for an Action Game',
      );

      expect(result.intent, AIIntent.elevenLabsMusic);
      expect(
        result.generationSpec!.prompt,
        'Heavy Metal BGM for an Action Game',
      );
    });

    test('elevenlabs_sfx intent is parsed with generation_spec', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({
          'intent': 'elevenlabs_sfx',
          'response_text': 'Creating thunderstorm sound effect.',
          'generation_spec': {
            'prompt': 'thunderstorm with heavy rain and lightning',
            'duration_seconds': 10.0,
          },
        }),
      );

      final result = await engine.process(
        'Create a sound effect of a thunderstorm',
      );

      expect(result.intent, AIIntent.elevenLabsSFX);
      expect(
        result.generationSpec!.prompt,
        'thunderstorm with heavy rain and lightning',
      );
      expect(result.generationSpec!.durationSeconds, 10.0);
    });

    test('unknown intent string defaults to generalQuery', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({
          'intent': 'some_unknown_intent',
          'response_text': 'Response text.',
        }),
      );

      final result = await engine.process('Hello');

      expect(result.intent, AIIntent.generalQuery);
    });
  });

  group('AIEngine error handling', () {
    test('throws when API key is empty', () async {
      SharedPreferences.setMockInitialValues({'ai_api_key': ''});
      SettingsService.resetInstance();

      final engine = AIEngine(
        connectivityGuard: _AlwaysOnlineConnectivityGuard(),
        httpClient: MockClient((_) async => http.Response('', 200)),
      );

      expect(
        () => engine.process('Hello'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('AI API key is not configured'),
          ),
        ),
      );
    });

    test('throws on non-200 API response', () async {
      final mockClient = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'Invalid API key'},
          }),
          401,
        ),
      );
      final engine = AIEngine(
        connectivityGuard: _AlwaysOnlineConnectivityGuard(),
        httpClient: mockClient,
      );

      await expectLater(
        engine.process('Hello'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('OpenAI API error (401)'),
          ),
        ),
      );
    });

    test(
      'falls back to generalQuery when response content is not valid JSON',
      () async {
        final mockClient = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'This is plain text, not JSON.',
                  },
                },
              ],
            }),
            200,
          ),
        );
        final engine = AIEngine(
          connectivityGuard: _AlwaysOnlineConnectivityGuard(),
          httpClient: mockClient,
        );

        final result = await engine.process('Hello');

        expect(result.intent, AIIntent.generalQuery);
        expect(result.responseText, 'This is plain text, not JSON.');
      },
    );
  });

  group('AIEngine JSON field handling', () {
    test('null generation_spec is handled gracefully', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({
          'intent': 'general_query',
          'response_text': 'Hello!',
          'generation_spec': null,
        }),
      );

      final result = await engine.process('Hello');

      expect(result.generationSpec, isNull);
    });

    test('null os_action is handled gracefully', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({
          'intent': 'general_query',
          'response_text': 'Hello!',
          'os_action': null,
        }),
      );

      final result = await engine.process('Hello');

      expect(result.osAction, isNull);
    });

    test('missing response_text defaults to empty string', () async {
      final engine = _engineWith(
        _mockOpenAIResponse({'intent': 'general_query'}),
      );

      final result = await engine.process('Hello');

      expect(result.responseText, '');
    });
  });
}
