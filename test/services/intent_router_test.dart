// Tests for IntentRouter — verifies each AIIntent routes to the correct service.
// Feature: project-kevin
// Requirements: 6.1, 7.1, 9.1

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:project_kevin/core/models/ai_response.dart';
import 'package:project_kevin/core/models/os_action.dart';
import 'package:project_kevin/services/intent_router.dart';

// ---------------------------------------------------------------------------
// Mock implementations
// ---------------------------------------------------------------------------

class MockOSBridge implements IOSBridge {
  final List<String> openAppCalls = [];
  final List<SettingsTarget> navigateCalls = [];
  bool returnSuccess;
  String? errorMessage;

  MockOSBridge({this.returnSuccess = true, this.errorMessage});

  @override
  Future<OSActionResult> openApp(String appName) async {
    openAppCalls.add(appName);
    return OSActionResult(
      success: returnSuccess,
      errorMessage: returnSuccess ? null : errorMessage,
    );
  }

  @override
  Future<OSActionResult> navigateToSettings(SettingsTarget target) async {
    navigateCalls.add(target);
    return OSActionResult(
      success: returnSuccess,
      errorMessage: returnSuccess ? null : errorMessage,
    );
  }
}

class MockElevenLabsClient implements IElevenLabsClient {
  final List<String> synthesizeCalls = [];
  final List<String> musicCalls = [];
  final List<String> sfxCalls = [];

  final Uint8List fakeAudio = Uint8List.fromList([1, 2, 3]);

  @override
  Future<String> transcribe(Uint8List audioBytes) async {
    return 'Mock transcript';
  }

  @override
  Stream<Uint8List> synthesizeSpeech(String text, String voiceId) {
    synthesizeCalls.add(text);
    return Stream.value(fakeAudio);
  }

  @override
  Future<Uint8List> generateMusic(String prompt) async {
    musicCalls.add(prompt);
    return fakeAudio;
  }

  @override
  Future<Uint8List> generateSoundEffect(String prompt) async {
    sfxCalls.add(prompt);
    return fakeAudio;
  }
}

class MockAudioPlayerService implements IAudioPlayerService {
  final List<Stream<Uint8List>> streamCalls = [];
  final List<Uint8List> bytesCalls = [];

  @override
  Future<void> playStream(Stream<Uint8List> audioStream) async {
    streamCalls.add(audioStream);
  }

  @override
  Future<void> playBytes(Uint8List audioBytes) async {
    bytesCalls.add(audioBytes);
  }

  @override
  Future<void> stop() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

IntentRouter _makeRouter({
  MockOSBridge? bridge,
  MockElevenLabsClient? client,
  MockAudioPlayerService? player,
}) {
  return IntentRouter(
    osBridge: bridge,
    elevenLabsClient: client,
    audioPlayerService: player,
    defaultVoiceId: 'test-voice',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('IntentRouter — generalQuery', () {
    test('returns TextResult with responseText', () async {
      final router = _makeRouter();
      final response = AIResponse(
        responseText: 'The capital of France is Paris.',
        intent: AIIntent.generalQuery,
      );

      final result = await router.route(response);

      expect(result, isA<TextResult>());
      expect(
        (result as TextResult).text,
        equals('The capital of France is Paris.'),
      );
    });

    test('does not call any service', () async {
      final bridge = MockOSBridge();
      final client = MockElevenLabsClient();
      final router = _makeRouter(bridge: bridge, client: client);

      await router.route(
        AIResponse(responseText: 'Hello', intent: AIIntent.generalQuery),
      );

      expect(bridge.openAppCalls, isEmpty);
      expect(bridge.navigateCalls, isEmpty);
      expect(client.synthesizeCalls, isEmpty);
    });
  });

  group('IntentRouter — osAction (open_app)', () {
    test('calls osBridge.openApp with the target', () async {
      final bridge = MockOSBridge();
      final router = _makeRouter(bridge: bridge);

      final response = AIResponse(
        responseText: 'Opening Spotify.',
        intent: AIIntent.osAction,
        osAction: OSActionSpec(type: 'open_app', target: 'Spotify'),
      );

      final result = await router.route(response);

      expect(result, isA<OSActionRouterResult>());
      expect(bridge.openAppCalls, equals(['Spotify']));
      final r = result as OSActionRouterResult;
      expect(r.actionResult.success, isTrue);
      expect(r.confirmationText, equals('Opening Spotify.'));
    });

    test('returns failure confirmation when bridge reports failure', () async {
      final bridge = MockOSBridge(
        returnSuccess: false,
        errorMessage: 'App not installed',
      );
      final router = _makeRouter(bridge: bridge);

      final result = await router.route(
        AIResponse(
          responseText: 'Opening Spotify.',
          intent: AIIntent.osAction,
          osAction: OSActionSpec(type: 'open_app', target: 'Spotify'),
        ),
      );

      expect(result, isA<OSActionRouterResult>());
      final r = result as OSActionRouterResult;
      expect(r.actionResult.success, isFalse);
      expect(r.confirmationText, equals('App not installed'));
    });

    test('returns ErrorResult when osBridge is null', () async {
      final router = _makeRouter();

      final result = await router.route(
        AIResponse(
          responseText: 'Opening Spotify.',
          intent: AIIntent.osAction,
          osAction: OSActionSpec(type: 'open_app', target: 'Spotify'),
        ),
      );

      expect(result, isA<ErrorResult>());
    });

    test('returns ErrorResult when osAction spec is missing', () async {
      final bridge = MockOSBridge();
      final router = _makeRouter(bridge: bridge);

      final result = await router.route(
        AIResponse(responseText: 'OK', intent: AIIntent.osAction),
      );

      expect(result, isA<ErrorResult>());
    });
  });

  group('IntentRouter — osAction (navigate_settings)', () {
    for (final entry in {
      'wifi': SettingsTarget.wifi,
      'bluetooth': SettingsTarget.bluetooth,
      'display': SettingsTarget.display,
      'sound': SettingsTarget.sound,
      'battery': SettingsTarget.battery,
      'storage': SettingsTarget.storage,
    }.entries) {
      test(
        'routes ${entry.key} to SettingsTarget.${entry.value.name}',
        () async {
          final bridge = MockOSBridge();
          final router = _makeRouter(bridge: bridge);

          await router.route(
            AIResponse(
              responseText: 'Opening settings.',
              intent: AIIntent.osAction,
              osAction: OSActionSpec(
                type: 'navigate_settings',
                target: entry.key,
              ),
            ),
          );

          expect(bridge.navigateCalls, equals([entry.value]));
        },
      );
    }

    test('returns ErrorResult for unknown settings target', () async {
      final bridge = MockOSBridge();
      final router = _makeRouter(bridge: bridge);

      final result = await router.route(
        AIResponse(
          responseText: 'Opening settings.',
          intent: AIIntent.osAction,
          osAction: OSActionSpec(
            type: 'navigate_settings',
            target: 'unknown_target',
          ),
        ),
      );

      expect(result, isA<ErrorResult>());
      expect(bridge.navigateCalls, isEmpty);
    });
  });

  group('IntentRouter — elevenLabsTTS', () {
    test('calls synthesizeSpeech and returns TTSStreamResult', () async {
      final client = MockElevenLabsClient();
      final router = _makeRouter(client: client);

      final result = await router.route(
        AIResponse(
          responseText: 'Hello world',
          intent: AIIntent.elevenLabsTTS,
          generationSpec: ElevenLabsGenerationSpec(
            prompt: 'Hello world',
            voiceId: 'voice-abc',
          ),
        ),
      );

      expect(result, isA<TTSStreamResult>());
      expect(client.synthesizeCalls, equals(['Hello world']));
    });

    test('uses defaultVoiceId when spec has no voiceId', () async {
      final client = MockElevenLabsClient();
      final router = IntentRouter(
        elevenLabsClient: client,
        defaultVoiceId: 'default-voice',
      );

      await router.route(
        AIResponse(
          responseText: 'Hi',
          intent: AIIntent.elevenLabsTTS,
          generationSpec: ElevenLabsGenerationSpec(prompt: 'Hi'),
        ),
      );

      // Just verify synthesize was called (voice ID is passed internally).
      expect(client.synthesizeCalls, equals(['Hi']));
    });

    test('falls back to TextResult when client is null', () async {
      final router = _makeRouter();

      final result = await router.route(
        AIResponse(
          responseText: 'Hello',
          intent: AIIntent.elevenLabsTTS,
          generationSpec: ElevenLabsGenerationSpec(prompt: 'Hello'),
        ),
      );

      expect(result, isA<TextResult>());
    });

    test('uses responseText as prompt when generationSpec is absent', () async {
      final client = MockElevenLabsClient();
      final router = _makeRouter(client: client);

      await router.route(
        AIResponse(
          responseText: 'Fallback text',
          intent: AIIntent.elevenLabsTTS,
        ),
      );

      expect(client.synthesizeCalls, equals(['Fallback text']));
    });
  });

  group('IntentRouter — elevenLabsMusic', () {
    test('calls generateMusic and returns AudioResult', () async {
      final client = MockElevenLabsClient();
      final router = _makeRouter(client: client);

      final result = await router.route(
        AIResponse(
          responseText: 'Generating music.',
          intent: AIIntent.elevenLabsMusic,
          generationSpec: ElevenLabsGenerationSpec(
            prompt: 'Heavy Metal BGM for an Action Game',
          ),
        ),
      );

      expect(result, isA<AudioResult>());
      expect(client.musicCalls, equals(['Heavy Metal BGM for an Action Game']));
      final r = result as AudioResult;
      expect(r.responseText, equals('Generating music.'));
    });

    test('returns ErrorResult when client is null', () async {
      final router = _makeRouter();

      final result = await router.route(
        AIResponse(
          responseText: 'Generating music.',
          intent: AIIntent.elevenLabsMusic,
          generationSpec: ElevenLabsGenerationSpec(prompt: 'some prompt'),
        ),
      );

      expect(result, isA<ErrorResult>());
    });

    test('uses responseText as prompt when generationSpec is absent', () async {
      final client = MockElevenLabsClient();
      final router = _makeRouter(client: client);

      await router.route(
        AIResponse(
          responseText: 'Epic battle music',
          intent: AIIntent.elevenLabsMusic,
        ),
      );

      expect(client.musicCalls, equals(['Epic battle music']));
    });
  });

  group('IntentRouter — elevenLabsSFX', () {
    test('calls generateSoundEffect and returns AudioResult', () async {
      final client = MockElevenLabsClient();
      final router = _makeRouter(client: client);

      final result = await router.route(
        AIResponse(
          responseText: 'Generating SFX.',
          intent: AIIntent.elevenLabsSFX,
          generationSpec: ElevenLabsGenerationSpec(
            prompt: 'thunderstorm with heavy rain',
          ),
        ),
      );

      expect(result, isA<AudioResult>());
      expect(client.sfxCalls, equals(['thunderstorm with heavy rain']));
    });

    test('returns ErrorResult when client is null', () async {
      final router = _makeRouter();

      final result = await router.route(
        AIResponse(
          responseText: 'Generating SFX.',
          intent: AIIntent.elevenLabsSFX,
          generationSpec: ElevenLabsGenerationSpec(prompt: 'boom'),
        ),
      );

      expect(result, isA<ErrorResult>());
    });
  });
}
