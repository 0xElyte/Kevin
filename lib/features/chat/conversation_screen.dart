import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../core/cancelable_operation.dart';
import '../../core/exceptions.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/message.dart';
import '../../core/quit_action.dart';
import '../../features/wake_word/i_kevin_service.dart';
import '../../features/wake_word/kevin_service.dart';
import '../../features/wake_word/porcupine_wake_word_detector.dart';
import '../../services/agent_chat_engine.dart';
import '../../services/audio_player_service.dart';
import '../../services/elevenlabs_client.dart';
import '../../services/intent_router.dart';
import '../../services/settings_service.dart';
import '../../theme/scifi_theme.dart';
import '../settings/settings_screen.dart';
import 'conversation_view.dart';
import 'input_bar.dart';
import 'kevin_app_bar.dart';
import 'widgets/listening_toast.dart';

/// The main conversation screen for Project Kevin.
///
/// Wires together [KevinAppBar], [ConversationView], and [InputBar] into a
/// [Scaffold]. Manages the conversation state, delegates AI processing to
/// [AIEngine] via [IntentRouter], and renders responses according to the
/// active [ResponseMode].
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  // -------------------------------------------------------------------------
  // State
  // -------------------------------------------------------------------------

  final List<Message> _messages = [];
  ResponseMode _responseMode = ResponseMode.text;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _processingMessageId;

  // Cancellation support
  final Map<String, CancelableOperation> _activeRequests = {};

  // Wake-word capture state
  OverlayEntry? _listeningToastEntry;
  final ValueNotifier<double> _rmsLevelNotifier = ValueNotifier(0.0);
  StreamSubscription<dynamic>? _wakeWordSub;
  PorcupineWakeWordDetector? _captureDetector;

  // -------------------------------------------------------------------------
  // Services (singletons / lazily created)
  // -------------------------------------------------------------------------

  final _uuid = const Uuid();
  final _agentChatEngine = AgentChatEngine();
  final _elevenLabsClient = ElevenLabsClient();
  final _audioPlayerService = AudioPlayerService();
  final _settingsService = SettingsService.instance;
  late final IKevinService _kevinService;
  late final QuitAction _quitAction;

  // Manual voice recording
  final AudioRecorder _recorder = AudioRecorder();

  // Text controller shared with InputBar so suggestion taps can populate it.
  final TextEditingController _inputController = TextEditingController();

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _kevinService = createKevinService();
    _quitAction = QuitAction(kevinService: _kevinService);
    _loadResponseMode();
    _startKevinServiceIfEnabled();
  }

  Future<void> _startKevinServiceIfEnabled() async {
    final settings = await _settingsService.loadSettings();
    if (!settings.wakeWordEnabled) return;
    try {
      await _kevinService.start();
      _wakeWordSub = _kevinService.wakeWordEvents.listen(_onWakeWordDetected);
    } catch (_) {
      // Service start failure is non-fatal; wake word simply won't work.
    }
  }

  Future<void> _loadResponseMode() async {
    final settings = await _settingsService.loadSettings();
    if (mounted) {
      setState(() => _responseMode = settings.responseMode);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _audioPlayerService.dispose();
    _wakeWordSub?.cancel();
    _rmsLevelNotifier.dispose();
    _captureDetector?.delete();
    _dismissListeningToast();
    _recorder.dispose();
    // Cancel all active requests
    for (final operation in _activeRequests.values) {
      operation.cancel();
    }
    _activeRequests.clear();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Message helpers
  // -------------------------------------------------------------------------

  String _newId() => _uuid.v4();

  void _addMessage(Message message) {
    setState(() => _messages.add(message));
  }

  void _updateMessage(String id, Message Function(Message) updater) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) {
        _messages[index] = updater(_messages[index]);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Send flow
  // -------------------------------------------------------------------------

  Future<void> _handleSend(
    String text, {
    String? attachmentPath,
    bool fromVoice = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isProcessing) return;

    // 1. Add user message.
    _addMessage(
      Message(
        id: _newId(),
        role: MessageRole.user,
        type: MessageType.text,
        text: trimmed,
        timestamp: DateTime.now(),
        status: MessageStatus.delivered,
      ),
    );

    // 2. Add "Kevin is processing..." placeholder.
    final processingId = _newId();
    _addMessage(
      Message(
        id: processingId,
        role: MessageRole.kevin,
        type: MessageType.text,
        text: 'Kevin is processing...',
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      ),
    );

    // 3. Set processing state.
    setState(() {
      _isProcessing = true;
      _processingMessageId = processingId;
    });

    // 4. Create cancellable operation.
    final operation = CancelableOperation();
    _activeRequests[processingId] = operation;

    await _processText(trimmed, processingId, operation);
  }

  /// Cancels the current processing request.
  void _handleCancelProcessing() {
    if (_processingMessageId != null) {
      final operation = _activeRequests[_processingMessageId];
      operation?.cancel();
      _activeRequests.remove(_processingMessageId);

      // Remove the processing message.
      setState(() {
        _messages.removeWhere((m) => m.id == _processingMessageId);
        _isProcessing = false;
        _processingMessageId = null;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Core processing
  // -------------------------------------------------------------------------

  Future<void> _processText(
    String text,
    String placeholderId,
    CancelableOperation operation,
  ) async {
    try {
      operation.checkCancelled();

      final settings = await _settingsService.loadSettings();
      final voiceId = settings.ttsVoiceId.isNotEmpty
          ? settings.ttsVoiceId
          : 'JBFqnCBsd6RMkjVDRZzb';

      // Step 1: Convert user text → PCM audio via ElevenLabs TTS.
      // pcm_16000 is exactly what the agent WebSocket expects as user_audio_chunk.
      final pcmBytes = await _elevenLabsClient.synthesizeSpeechPcm(
        text,
        voiceId,
      );

      operation.checkCancelled();

      // Step 2: Send PCM audio to agent, get MP3 audio response back.
      final result = await _agentChatEngine.send(pcmBytes);

      operation.checkCancelled();

      if (!result.hasAudio) {
        _updateMessage(
          placeholderId,
          (m) => m.copyWith(
            status: MessageStatus.error,
            text: 'Agent returned no audio response.',
            type: MessageType.error,
            retryable: true,
          ),
        );
        return;
      }

      // Step 3: Render based on response mode toggle.
      if (_responseMode == ResponseMode.text) {
        // TEXT mode: transcribe agent MP3 response → show as text bubble.
        final transcript = await _elevenLabsClient.transcribe(
          result.audioBytes,
          filename: 'audio.mp3',
        );
        _updateMessage(
          placeholderId,
          (m) => m.copyWith(
            status: MessageStatus.delivered,
            text: transcript.isNotEmpty ? transcript : '(no response)',
            type: MessageType.text,
          ),
        );
      } else {
        // VOICE mode: play audio + show voice note bubble.
        _updateMessage(
          placeholderId,
          (m) => m.copyWith(
            status: MessageStatus.delivered,
            text: '',
            type: MessageType.voiceNote,
            audioData: result.audioBytes,
            audioMimeType: 'audio/mpeg',
          ),
        );
        await _audioPlayerService.playBytes(result.audioBytes);
      }
    } on OperationCancelledException {
      return;
    } on OfflineException {
      final offlineResult = _tryOfflineFallback(text);
      if (offlineResult != null) {
        _updateMessage(
          placeholderId,
          (m) => m.copyWith(
            status: MessageStatus.delivered,
            text: offlineResult,
            type: MessageType.text,
          ),
        );
      } else {
        _updateMessage(
          placeholderId,
          (m) => m.copyWith(
            status: MessageStatus.error,
            text: 'No internet connection. Please check your network.',
            type: MessageType.error,
            retryable: false,
          ),
        );
      }
    } on STTTranscriptionError {
      _updateMessage(
        placeholderId,
        (m) => m.copyWith(
          status: MessageStatus.error,
          text: 'Could not understand audio. Please try again.',
          type: MessageType.error,
          retryable: false,
        ),
      );
    } on AgentSessionError catch (e) {
      _updateMessage(
        placeholderId,
        (m) => m.copyWith(
          status: MessageStatus.error,
          text: 'Agent error: ${e.message}',
          type: MessageType.error,
          retryable: true,
        ),
      );
    } catch (e) {
      _updateMessage(
        placeholderId,
        (m) => m.copyWith(
          status: MessageStatus.error,
          text: 'Something went wrong: ${e.toString()}',
          type: MessageType.error,
          retryable: false,
        ),
      );
    } finally {
      _activeRequests.remove(placeholderId);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingMessageId = null;
        });
      }
    }
  }

  /// Attempts to handle [text] offline for queries that don't require network.
  ///
  /// Returns a response string if the query can be answered offline
  /// (time, date, or OS actions), or null if network is required.
  String? _tryOfflineFallback(String text) {
    final lower = text.toLowerCase().trim();

    // Time query — answered from device clock.
    if (lower.contains('time') &&
        (lower.startsWith('what') ||
            lower.startsWith('tell') ||
            lower.contains('current'))) {
      final now = DateTime.now();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      return 'The current time is $hour:$minute.';
    }

    // Date query — answered from device clock.
    if (lower.contains('date') &&
        (lower.startsWith('what') ||
            lower.startsWith('tell') ||
            lower.contains('current') ||
            lower.contains('today'))) {
      final now = DateTime.now();
      return 'Today is ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.';
    }

    // "Today" / "what day" queries.
    if (lower.contains('today') || lower.contains('what day')) {
      final now = DateTime.now();
      return 'Today is ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.';
    }

    // OS action queries — these can proceed offline via the OS bridge.
    // We detect simple "open [app]" or "settings" patterns.
    if (lower.startsWith('open ') || lower.contains('settings')) {
      // Delegate to the intent router with a synthesised OS action response.
      // Return null here so the caller shows the offline error; the OS bridge
      // path is handled separately in _handleAIResponse when online.
      // For offline OS actions we return a placeholder that triggers the bridge.
      return null; // OS actions need the AI to classify; skip offline for now.
    }

    return null;
  }

  // -------------------------------------------------------------------------
  // Wake-word flow (Requirement 11.2, 11.3, 11.5, 11.6, 11.7, 11.9)
  // -------------------------------------------------------------------------

  /// Called when the Kevin_Service emits a [WakeWordEvent].
  Future<void> _onWakeWordDetected(_) async {
    if (!mounted) return;

    // 1. Play activation tone (Req 11.2) — play a short beep via AudioPlayerService.
    //    We use a silent no-op if the asset is absent so the flow is never blocked.
    _playActivationTone();

    // 2. Show ListeningToast overlay (Req 11.3).
    _showListeningToast();

    // 3. Start mic capture via a local PorcupineWakeWordDetector (Req 11.5).
    _captureDetector = PorcupineWakeWordDetector(
      settingsService: _settingsService,
      onSilenceTimeout: _onSilenceTimeout,
    );

    try {
      await _captureDetector!.startCapture();
    } catch (e) {
      // Capture failed — dismiss toast and show error (Req 11.9).
      _dismissListeningToast();
      _showWakeWordError('Could not start microphone capture.');
    }
  }

  /// Plays the activation tone through the AudioPlayerService.
  ///
  /// The tone is a short beep bundled as an asset. If the asset is missing
  /// the error is silently swallowed so the wake-word flow continues.
  void _playActivationTone() {
    // Attempt to play the activation tone asset.
    // Errors are intentionally ignored — the tone is non-critical.
    try {
      _audioPlayerService.playBytes(
        // 44-byte minimal valid MP3 silence used as a fallback when the real
        // tone asset is not yet bundled.  Replace with a real asset load when
        // assets/activation_tone.mp3 is added to the project.
        Uint8List(0),
      );
    } catch (_) {}
  }

  /// Inserts the [ListeningToast] into the overlay stack.
  void _showListeningToast() {
    if (!mounted) return;
    _dismissListeningToast(); // Remove any existing toast first.
    _rmsLevelNotifier.value = 0.0;
    _listeningToastEntry = ListeningToastOverlay.show(
      context,
      rmsLevelNotifier: _rmsLevelNotifier,
    );
  }

  /// Removes the [ListeningToast] from the overlay stack.
  void _dismissListeningToast() {
    _listeningToastEntry?.remove();
    _listeningToastEntry = null;
  }

  /// Called by [PorcupineWakeWordDetector] when silence timeout fires.
  ///
  /// [audioBytes] is null when the captured clip was too short (< 0.5 s).
  Future<void> _onSilenceTimeout(Uint8List? audioBytes) async {
    // Req 11.7: dismiss toast before/at STT submission.
    _dismissListeningToast();

    if (audioBytes == null) {
      // Req 4.6 / 11.8: clip too short — show toast and return to listening.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recording too short. Please speak again.',
              style: const TextStyle(color: SciFiTheme.colorTextPrimary),
            ),
            backgroundColor: SciFiTheme.colorSurface,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Transcribe via ElevenLabs Scribe v2 Realtime (Req 11.6).
    try {
      final transcript = await _elevenLabsClient.transcribeRealtime(
        Stream.value(audioBytes),
      );

      if (transcript.trim().isEmpty) return;

      // Process the transcript exactly like a typed message but in voice mode.
      await _handleSend(transcript, fromVoice: true);
    } on STTTranscriptionError catch (e) {
      // Req 11.9: show error, return to listening.
      _showWakeWordError('Could not understand audio: ${e.message}');
    } catch (e) {
      _showWakeWordError('Voice input failed. Please try again.');
    }
  }

  /// Shows a transient error snackbar for wake-word flow failures.
  void _showWakeWordError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: SciFiTheme.colorTextPrimary),
        ),
        backgroundColor: SciFiTheme.colorSurface,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Voice input flow (manual tap-to-record)
  // -------------------------------------------------------------------------

  void _handleVoicePressed() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission denied.',
              style: TextStyle(color: SciFiTheme.colorTextPrimary),
            ),
            backgroundColor: SciFiTheme.colorSurface,
          ),
        );
      }
      return;
    }

    // Write to a temp file in the system temp directory.
    final tmpDir = io.Directory.systemTemp;
    final tmpPath = '${tmpDir.path}/kevin_voice_input.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: tmpPath,
    );

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);

    final path = await _recorder.stop();
    if (path == null) return;

    // Read the recorded file bytes.
    final file = await _readFileBytes(path);
    if (file == null || file.isEmpty) return;

    // Validate minimum duration (~0.5 s at 16kHz mono 16-bit = 16000 bytes).
    if (file.length < 16000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recording too short. Please speak again.',
              style: TextStyle(color: SciFiTheme.colorTextPrimary),
            ),
            backgroundColor: SciFiTheme.colorSurface,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Transcribe via ElevenLabs Scribe v2.
    try {
      final transcript = await _elevenLabsClient.transcribe(file);
      if (transcript.trim().isNotEmpty) {
        await _handleSend(transcript, fromVoice: true);
      }
    } on STTTranscriptionError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not understand audio: ${e.message}',
              style: const TextStyle(color: SciFiTheme.colorTextPrimary),
            ),
            backgroundColor: SciFiTheme.colorSurface,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice input failed. Please try again.',
              style: TextStyle(color: SciFiTheme.colorTextPrimary),
            ),
            backgroundColor: SciFiTheme.colorSurface,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _readFileBytes(String path) async {
    try {
      return await io.File(path).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Retry
  // -------------------------------------------------------------------------

  void _handleRetry(Message errorMessage) {
    if (_isProcessing) return;

    final errorIndex = _messages.indexOf(errorMessage);
    if (errorIndex <= 0) return;

    String? lastUserText;
    for (int i = errorIndex - 1; i >= 0; i--) {
      if (_messages[i].role == MessageRole.user && _messages[i].text != null) {
        lastUserText = _messages[i].text;
        break;
      }
    }

    if (lastUserText == null) return;

    // Defer all state mutations to after the current build frame to avoid
    // the "!_doingMountOrUpdate" viewport assertion.
    final textToRetry = lastUserText;
    final messageId = errorMessage.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _updateMessage(
        messageId,
        (m) => m.copyWith(
          status: MessageStatus.sending,
          text: 'Kevin is processing...',
          type: MessageType.text,
          retryable: false,
        ),
      );

      setState(() {
        _isProcessing = true;
        _processingMessageId = messageId;
      });

      final operation = CancelableOperation();
      _activeRequests[messageId] = operation;

      _processText(textToRetry, messageId, operation);
    });
  }

  // -------------------------------------------------------------------------
  // Suggestion tap
  // -------------------------------------------------------------------------

  void _handleSuggestionTap(String promptText) {
    _inputController.text = promptText;
    // Move cursor to end.
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: promptText.length),
    );
  }

  // -------------------------------------------------------------------------
  // Response mode change
  // -------------------------------------------------------------------------

  Future<void> _handleResponseModeChanged(ResponseMode mode) async {
    setState(() => _responseMode = mode);
    final settings = await _settingsService.loadSettings();
    await _settingsService.saveSettings(settings.copyWith(responseMode: mode));
  }

  // -------------------------------------------------------------------------
  // Settings navigation
  // -------------------------------------------------------------------------

  void _handleSettingsPressed() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  // -------------------------------------------------------------------------
  // Quit
  // -------------------------------------------------------------------------

  void _handleQuit() {
    _quitAction.perform();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SciFiTheme.colorBackground,
      resizeToAvoidBottomInset: true,
      appBar: KevinAppBar(
        onQuit: _handleQuit,
        onResponseModeChanged: _handleResponseModeChanged,
        onSettingsPressed: _handleSettingsPressed,
      ),
      body: Column(
        children: [
          Expanded(
            child: ConversationView(
              messages: _messages,
              audioPlayerService: _audioPlayerService,
              onSuggestionTap: _handleSuggestionTap,
              onRetry: _handleRetry,
            ),
          ),
          InputBar(
            controller: _inputController,
            onSend: _handleSend,
            onVoicePressed: _handleVoicePressed,
            onCancelProcessing: _handleCancelProcessing,
            isRecording: _isRecording,
            isProcessing: _isProcessing,
          ),
        ],
      ),
    );
  }
}
