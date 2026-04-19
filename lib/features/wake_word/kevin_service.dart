import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../core/models/wake_word_event.dart';
import '../../services/settings_service.dart';
import 'i_kevin_service.dart';
import 'porcupine_wake_word_detector.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Broadcast action key sent by the "Quit" notification button on Android.
// ─────────────────────────────────────────────────────────────────────────────
const String kQuitAction = 'com.projectkevin.QUIT_ACTION';

// ─────────────────────────────────────────────────────────────────────────────
// Android foreground-service task handler
// ─────────────────────────────────────────────────────────────────────────────

/// Entry-point executed inside the foreground-service isolate on Android.
@pragma('vm:entry-point')
void _androidTaskHandler() {
  FlutterForegroundTask.setTaskHandler(_KevinTaskHandler());
}

class _KevinTaskHandler extends TaskHandler {
  PorcupineWakeWordDetector? _detector;
  StreamSubscription<WakeWordEvent>? _sub;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _detector = PorcupineWakeWordDetector(
      settingsService: SettingsService.instance,
    );
    _sub = _detector!.wakeWordEvents.listen((event) {
      FlutterForegroundTask.sendDataToMain({
        'detectedAt': event.detectedAt.toIso8601String(),
        'confidence': event.confidence,
      });
    });
    await _detector!.start();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // No periodic work needed; Porcupine runs continuously.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _sub?.cancel();
    await _detector?.delete();
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'quit') {
      FlutterForegroundTask.sendDataToMain({'action': kQuitAction});
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kevin_Service — Android implementation
// ─────────────────────────────────────────────────────────────────────────────

/// Android foreground-service implementation of [IKevinService].
///
/// Requirements: 12.1, 12.2, 12.5, 12.7, 12.8, 12.9, 12.10, 12.11
class AndroidKevinService implements IKevinService {
  final _eventController = StreamController<WakeWordEvent>.broadcast();
  bool _isRunning = false;
  late final DataCallback _dataCallback;

  AndroidKevinService() {
    _dataCallback = _onTaskData;
  }

  @override
  bool get isRunning => _isRunning;

  @override
  Stream<WakeWordEvent> get wakeWordEvents => _eventController.stream;

  @override
  Future<void> start() async {
    if (_isRunning) return;

    _initForegroundTask();
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_dataCallback);

    final result = await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'Kevin is active',
      notificationText: 'Wake word detection running',
      notificationIcon: null,
      notificationButtons: [
        const NotificationButton(id: 'open', text: 'Open Kevin'),
        const NotificationButton(id: 'quit', text: 'Quit'),
      ],
      callback: _androidTaskHandler,
    );

    if (result is ServiceRequestSuccess) {
      _isRunning = true;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isRunning) return;
    FlutterForegroundTask.removeTaskDataCallback(_dataCallback);
    await FlutterForegroundTask.stopService();
    _isRunning = false;
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'kevin_service_channel',
        channelName: 'Kevin Service',
        channelDescription: 'Kevin wake word detection service',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
  }

  void _onTaskData(Object data) {
    if (data is Map) {
      if (data.containsKey('detectedAt')) {
        final event = WakeWordEvent(
          detectedAt: DateTime.parse(data['detectedAt'] as String),
          confidence: (data['confidence'] as num).toDouble(),
        );
        _eventController.add(event);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kevin_Service — Windows implementation
// ─────────────────────────────────────────────────────────────────────────────

class _WakeWordMessage {
  final DateTime detectedAt;
  final double confidence;
  _WakeWordMessage(this.detectedAt, this.confidence);
}

@pragma('vm:entry-point')
Future<void> _windowsIsolateEntry(SendPort sendPort) async {
  final detector = PorcupineWakeWordDetector(
    settingsService: SettingsService.instance,
  );
  detector.wakeWordEvents.listen((event) {
    sendPort.send(_WakeWordMessage(event.detectedAt, event.confidence));
  });
  await detector.start();

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  await for (final msg in receivePort) {
    if (msg == 'stop') {
      await detector.delete();
      receivePort.close();
      break;
    }
  }
}

/// Windows background-process implementation of [IKevinService].
///
/// Requirements: 12.1, 12.2
class WindowsKevinService implements IKevinService {
  final _eventController = StreamController<WakeWordEvent>.broadcast();
  Isolate? _isolate;
  SendPort? _isolateControl;
  ReceivePort? _receivePort;
  StreamSubscription? _portSub;
  bool _isRunning = false;

  @override
  bool get isRunning => _isRunning;

  @override
  Stream<WakeWordEvent> get wakeWordEvents => _eventController.stream;

  @override
  Future<void> start() async {
    if (_isRunning) return;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _windowsIsolateEntry,
      _receivePort!.sendPort,
    );

    bool controlPortReceived = false;
    _portSub = _receivePort!.listen((msg) {
      if (!controlPortReceived && msg is SendPort) {
        _isolateControl = msg;
        controlPortReceived = true;
        return;
      }
      if (msg is _WakeWordMessage) {
        _eventController.add(
          WakeWordEvent(detectedAt: msg.detectedAt, confidence: msg.confidence),
        );
      }
    });

    _isRunning = true;
  }

  @override
  Future<void> stop() async {
    if (!_isRunning) return;
    _isolateControl?.send('stop');
    await _portSub?.cancel();
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateControl = null;
    _receivePort = null;
    _isRunning = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the platform-appropriate [IKevinService] implementation.
IKevinService createKevinService() {
  if (Platform.isAndroid) return AndroidKevinService();
  if (Platform.isWindows) return WindowsKevinService();
  throw UnsupportedError(
    'Kevin_Service is only supported on Android and Windows.',
  );
}
