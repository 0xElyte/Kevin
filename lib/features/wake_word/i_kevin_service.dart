import 'dart:async';

import '../../core/models/wake_word_event.dart';

/// Abstract interface for the Kevin background service.
///
/// On Android this is backed by a foreground service (flutter_foreground_task).
/// On Windows this is backed by a system-tray background process with a Dart
/// isolate running Porcupine.
///
/// Requirements: 12.1, 12.2, 12.3
abstract class IKevinService {
  /// Starts the background service and the wake word detector.
  Future<void> start();

  /// Stops the background service and the wake word detector.
  /// Called by [Quit_Action].
  Future<void> stop();

  /// Stream of [WakeWordEvent]s emitted each time "Hey Kevin" is detected.
  Stream<WakeWordEvent> get wakeWordEvents;

  /// Whether the service is currently running.
  bool get isRunning;
}
