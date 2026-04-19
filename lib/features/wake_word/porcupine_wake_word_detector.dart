import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:record/record.dart';

import '../../core/models/wake_word_event.dart';
import '../../services/settings_service.dart';

/// Silence detection threshold in dBFS.
/// Values above this are considered "speech"; below is "silence".
const double _kSilenceThresholdDbfs = -40.0;

/// Duration of continuous silence that triggers STT submission.
const Duration _kSilenceTimeout = Duration(seconds: 2);

/// Minimum captured audio duration; shorter clips are discarded.
const Duration _kMinAudioDuration = Duration(milliseconds: 500);

/// Amplitude polling interval while capturing post-wake-word audio.
const Duration _kAmplitudePollInterval = Duration(milliseconds: 100);

/// Callback invoked when silence timeout fires with the captured audio bytes.
/// If [audioBytes] is null the clip was too short and was discarded.
typedef SilenceTimeoutCallback = void Function(Uint8List? audioBytes);

/// On-device wake word detector powered by Picovoice Porcupine.
///
/// Usage:
/// ```dart
/// final detector = PorcupineWakeWordDetector(
///   settingsService: SettingsService.instance,
/// );
/// detector.wakeWordEvents.listen((event) { ... });
/// await detector.start();
/// ```
///
/// After a wake word is detected the detector exposes [isCapturing] and
/// fires [onSilenceTimeout] once 2 s of silence have elapsed.
///
/// Requirements: 11.1, 11.6, 11.8, 12.1
class PorcupineWakeWordDetector {
  final SettingsService _settingsService;

  PorcupineManager? _manager;
  final _eventController = StreamController<WakeWordEvent>.broadcast();

  bool _isActive = false;
  bool _isCapturing = false;

  // ── silence / capture state ──────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _amplitudeTimer;
  DateTime? _captureStart;
  final List<Uint8List> _capturedChunks = [];
  StreamSubscription<Uint8List>? _recordStreamSub;

  /// Callback fired when silence timeout elapses.
  /// Receives the captured audio bytes, or null if the clip was too short.
  SilenceTimeoutCallback? onSilenceTimeout;

  PorcupineWakeWordDetector({
    SettingsService? settingsService,
    this.onSilenceTimeout,
  }) : _settingsService = settingsService ?? SettingsService.instance;

  // ── public API ────────────────────────────────────────────────────────────

  /// Stream of [WakeWordEvent]s emitted each time "Hey Kevin" is detected.
  Stream<WakeWordEvent> get wakeWordEvents => _eventController.stream;

  /// Whether the Porcupine engine is currently listening for the wake word.
  bool get isActive => _isActive;

  /// Whether the detector is currently capturing post-wake-word audio.
  bool get isCapturing => _isCapturing;

  /// Initialises Porcupine and starts continuous wake word listening.
  ///
  /// Loads `hey-kevin.ppn` from the app's asset bundle and configures
  /// sensitivity to 0.5 as specified in the design document.
  Future<void> start() async {
    if (_isActive) return;

    final settings = await _settingsService.loadSettings();
    final accessKey = settings.picovoiceApiKey;

    _manager = await PorcupineManager.fromKeywordPaths(
      accessKey,
      ['assets/hey-kevin.ppn'],
      _onWakeWord,
      sensitivities: [0.5],
      errorCallback: _onPorcupineError,
    );

    await _manager!.start();
    _isActive = true;
  }

  /// Stops wake word listening and releases the Porcupine engine.
  Future<void> stop() async {
    if (!_isActive) return;
    await _manager?.stop();
    _isActive = false;
  }

  /// Stops listening and frees all native resources.
  Future<void> delete() async {
    _isActive = false;
    await _stopCapture(submit: false);
    await _manager?.delete();
    _manager = null;
    await _eventController.close();
  }

  // ── silence / capture ─────────────────────────────────────────────────────

  /// Starts capturing microphone audio after a wake word event.
  ///
  /// Monitors amplitude every [_kAmplitudePollInterval]. If the level stays
  /// below [_kSilenceThresholdDbfs] for [_kSilenceTimeout], capture stops
  /// and [onSilenceTimeout] is called with the collected bytes (or null if
  /// the clip is shorter than [_kMinAudioDuration]).
  Future<void> startCapture() async {
    if (_isCapturing) return;
    _isCapturing = true;
    _captureStart = DateTime.now();
    _capturedChunks.clear();

    final audioStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _recordStreamSub = audioStream.listen(
      (chunk) => _capturedChunks.add(chunk),
      onError: (_) => _stopCapture(submit: false),
      cancelOnError: true,
    );

    _startSilenceMonitor();
  }

  void _startSilenceMonitor() {
    DateTime? silenceStart;

    _amplitudeTimer = Timer.periodic(_kAmplitudePollInterval, (_) async {
      if (!_isCapturing) return;

      final amp = await _recorder.getAmplitude();
      final dbfs = amp.current; // dBFS value (negative; 0 = max)

      if (dbfs < _kSilenceThresholdDbfs) {
        silenceStart ??= DateTime.now();
        final silenceDuration = DateTime.now().difference(silenceStart!);
        if (silenceDuration >= _kSilenceTimeout) {
          await _stopCapture(submit: true);
        }
      } else {
        silenceStart = null;
      }
    });
  }

  Future<void> _stopCapture({required bool submit}) async {
    if (!_isCapturing) return;
    _isCapturing = false;

    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    await _recordStreamSub?.cancel();
    _recordStreamSub = null;
    await _recorder.stop();

    if (!submit) {
      _capturedChunks.clear();
      onSilenceTimeout?.call(null);
      return;
    }

    final capturedDuration = _captureStart != null
        ? DateTime.now().difference(_captureStart!)
        : Duration.zero;

    if (capturedDuration < _kMinAudioDuration) {
      // Clip too short — discard without submitting.
      _capturedChunks.clear();
      onSilenceTimeout?.call(null);
    } else {
      final totalLength = _capturedChunks.fold<int>(
        0,
        (sum, chunk) => sum + chunk.length,
      );
      final combined = Uint8List(totalLength);
      var offset = 0;
      for (final chunk in _capturedChunks) {
        combined.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      _capturedChunks.clear();
      onSilenceTimeout?.call(combined);
    }
  }

  // ── private helpers ───────────────────────────────────────────────────────

  void _onWakeWord(int keywordIndex) {
    _eventController.add(
      WakeWordEvent(detectedAt: DateTime.now(), confidence: 0.5),
    );
  }

  void _onPorcupineError(PorcupineException error) {
    _eventController.addError(error);
  }

  /// Computes the RMS level (0.0–1.0) from a PCM-16 audio chunk.
  ///
  /// Exposed as a static utility so the UI layer can use it for the
  /// [VoiceInputMeter] without depending on the recorder directly.
  static double computeRms(Uint8List pcm16Bytes) {
    if (pcm16Bytes.isEmpty) return 0.0;

    final data = ByteData.sublistView(pcm16Bytes);
    double sumSquares = 0.0;
    final sampleCount = pcm16Bytes.length ~/ 2;

    for (var i = 0; i < sampleCount; i++) {
      final sample = data.getInt16(i * 2, Endian.little) / 32768.0;
      sumSquares += sample * sample;
    }

    return math.sqrt(sumSquares / sampleCount).clamp(0.0, 1.0);
  }
}
