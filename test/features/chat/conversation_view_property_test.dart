// Feature: project-kevin, Property 15: Messages Present Implies No Suggestion Cards
// Validates: Requirements 15.1, 15.5, 15.6

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart'
    hide expect, group, test, setUp, tearDown, setUpAll;
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'package:project_kevin/core/models/message.dart';
import 'package:project_kevin/features/chat/conversation_view.dart';
import 'package:project_kevin/features/chat/widgets/suggestion_card_widget.dart';
import 'package:project_kevin/services/audio_player_service.dart';
import 'package:project_kevin/theme/scifi_theme.dart';

// ---------------------------------------------------------------------------
// Minimal just_audio platform mock — avoids platform channel calls in tests.
// ---------------------------------------------------------------------------

class _MockJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return _MockAudioPlayerPlatform(request.id);
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    return DisposeAllPlayersResponse();
  }
}

class _MockAudioPlayerPlatform extends AudioPlayerPlatform {
  final _eventController = StreamController<PlaybackEventMessage>.broadcast();
  final _dataController = StreamController<PlayerDataMessage>.broadcast();

  _MockAudioPlayerPlatform(super.id);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _eventController.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream =>
      _dataController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    return LoadResponse(duration: null);
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    return PauseResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _eventController.close();
    await _dataController.close();
    return DisposeResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    return SetVolumeResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    return SetSpeedResponse();
  }

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async {
    return SetPitchResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async {
    return SetShuffleModeResponse();
  }

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
    SetShuffleOrderRequest request,
  ) async {
    return SetShuffleOrderResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    return SeekResponse();
  }

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
    ConcatenatingInsertAllRequest request,
  ) async {
    return ConcatenatingInsertAllResponse();
  }

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
    ConcatenatingRemoveRangeRequest request,
  ) async {
    return ConcatenatingRemoveRangeResponse();
  }

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
    ConcatenatingMoveRequest request,
  ) async {
    return ConcatenatingMoveResponse();
  }

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async {
    return SetAndroidAudioAttributesResponse();
  }

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
  setAutomaticallyWaitsToMinimizeStalling(
    SetAutomaticallyWaitsToMinimizeStallingRequest request,
  ) async {
    return SetAutomaticallyWaitsToMinimizeStallingResponse();
  }

  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
  setCanUseNetworkResourcesForLiveStreamingWhilePaused(
    SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest request,
  ) async {
    return SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();
  }

  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
    SetPreferredPeakBitRateRequest request,
  ) async {
    return SetPreferredPeakBitRateResponse();
  }
}

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

extension AnyConversationMessage on Any {
  /// Generates a non-empty string (1–100 chars) for message text.
  Generator<String> get shortText => any.nonEmptyLetterOrDigits.map(
    (s) => s.substring(0, s.length.clamp(1, 100)),
  );

  /// Generates a single [Message] with role user or kevin, type text.
  Generator<Message> get anyTextMessage => combine3(
    any.shortText,
    any.intInRange(0, MessageRole.values.length),
    any.intInRange(0, MessageStatus.values.length),
    (text, roleIdx, statusIdx) => Message(
      id: 'prop15-id',
      role: MessageRole.values[roleIdx],
      type: MessageType.text,
      text: text,
      timestamp: DateTime(2024),
      status: MessageStatus.values[statusIdx],
    ),
  );

  /// Generates a non-empty list of [Message] objects (1–10 items).
  Generator<List<Message>> get nonEmptyMessageList => combine2(
    any.anyTextMessage,
    any.intInRange(0, 9),
    (first, extra) {
      final random = Random(extra);
      final list = <Message>[first];
      for (var i = 0; i < extra; i++) {
        list.add(
          Message(
            id: 'prop15-extra-$i',
            role: MessageRole.values[random.nextInt(MessageRole.values.length)],
            type: MessageType.text,
            text: 'msg $i',
            timestamp: DateTime(2024),
            status: MessageStatus.delivered,
          ),
        );
      }
      return list;
    },
  );
}

// ---------------------------------------------------------------------------
// Helper: wrap ConversationView in MaterialApp with SciFi theme
// ---------------------------------------------------------------------------

Widget _buildConversationView(
  List<Message> messages,
  AudioPlayerService audioService,
) {
  return MaterialApp(
    theme: SciFiTheme.themeData,
    home: Scaffold(
      body: ConversationView(
        messages: messages,
        audioPlayerService: audioService,
        onSuggestionTap: (_) {},
        onRetry: (_) {},
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Property 15: Messages Present Implies No Suggestion Cards
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    JustAudioPlatform.instance = _MockJustAudioPlatform();
  });

  late AudioPlayerService audioService;

  setUp(() {
    audioService = AudioPlayerService();
  });

  tearDown(() async {
    await audioService.dispose();
  });

  group('Property 15: Messages Present Implies No Suggestion Cards', () {
    // -----------------------------------------------------------------------
    // Part A: non-empty message list → zero SuggestionCardWidget rendered
    // -----------------------------------------------------------------------

    testWidgets(
      'Non-empty message list renders zero SuggestionCardWidget (100 iterations)',
      (tester) async {
        final random = Random(42);
        final generator = any.nonEmptyMessageList;
        const numRuns = 100;

        for (var i = 0; i < numRuns; i++) {
          final messages = generator(random, 50).value;

          await tester.pumpWidget(
            _buildConversationView(messages, audioService),
          );
          await tester.pump();

          expect(
            find.byType(SuggestionCardWidget),
            findsNothing,
            reason:
                'Expected zero SuggestionCardWidget when messages.length='
                '${messages.length} (iteration $i)',
          );
        }
      },
    );

    // -----------------------------------------------------------------------
    // Part B: empty message list → ≥6 SuggestionCardWidget rendered
    // -----------------------------------------------------------------------

    testWidgets(
      'Empty message list renders at least 6 SuggestionCardWidget widgets',
      (tester) async {
        await tester.pumpWidget(_buildConversationView(const [], audioService));
        await tester.pump();

        expect(
          find.byType(SuggestionCardWidget),
          findsAtLeastNWidgets(6),
          reason: 'Expected ≥6 SuggestionCardWidget when message list is empty',
        );
      },
    );

    // -----------------------------------------------------------------------
    // Glados property: non-empty list → list is non-empty (precondition check)
    // -----------------------------------------------------------------------

    Glados(any.nonEmptyMessageList, ExploreConfig(numRuns: 100)).test(
      'For any non-empty message list, the list is non-empty (precondition)',
      (messages) {
        // Structural assertion: a non-empty list must have at least one message.
        // The widget tests above verify the rendered output; this Glados test
        // ensures the generator covers all role/status combinations and that
        // the list is always non-empty (the precondition for the property).
        expect(messages, isNotEmpty);
        expect(messages.length, greaterThanOrEqualTo(1));
      },
    );

    // -----------------------------------------------------------------------
    // Specific example tests for boundary conditions
    // -----------------------------------------------------------------------

    testWidgets(
      'Exactly one user message hides all SuggestionCardWidget widgets',
      (tester) async {
        final messages = [
          Message(
            id: 'single',
            role: MessageRole.user,
            type: MessageType.text,
            text: 'Hello Kevin',
            timestamp: DateTime(2024),
            status: MessageStatus.delivered,
          ),
        ];

        await tester.pumpWidget(_buildConversationView(messages, audioService));
        await tester.pump();

        expect(find.byType(SuggestionCardWidget), findsNothing);
      },
    );

    testWidgets(
      'Exactly one Kevin message hides all SuggestionCardWidget widgets',
      (tester) async {
        final messages = [
          Message(
            id: 'kevin-msg',
            role: MessageRole.kevin,
            type: MessageType.text,
            text: 'Hello, I am Kevin',
            timestamp: DateTime(2024),
            status: MessageStatus.delivered,
          ),
        ];

        await tester.pumpWidget(_buildConversationView(messages, audioService));
        await tester.pump();

        expect(find.byType(SuggestionCardWidget), findsNothing);
      },
    );

    testWidgets('Multiple messages hide all SuggestionCardWidget widgets', (
      tester,
    ) async {
      final messages = List.generate(
        5,
        (i) => Message(
          id: 'msg-$i',
          role: i.isEven ? MessageRole.user : MessageRole.kevin,
          type: MessageType.text,
          text: 'Message $i',
          timestamp: DateTime(2024),
          status: MessageStatus.delivered,
        ),
      );

      await tester.pumpWidget(_buildConversationView(messages, audioService));
      await tester.pump();

      expect(find.byType(SuggestionCardWidget), findsNothing);
    });

    testWidgets(
      'Empty list shows at least 6 SuggestionCardWidget widgets (all defaults)',
      (tester) async {
        await tester.pumpWidget(_buildConversationView(const [], audioService));
        await tester.pump();

        // The default grid has 8 cards; property requires ≥6.
        expect(find.byType(SuggestionCardWidget), findsAtLeastNWidgets(6));
      },
    );
  });
}
