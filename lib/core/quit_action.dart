import 'dart:io';

import 'package:flutter/services.dart';

import '../features/wake_word/i_kevin_service.dart';

/// Performs a full application shutdown.
///
/// Quit_Action:
///   1. Stops the [IKevinService] (stops the foreground/background service and
///      the Wake_Word_Detector, and dismisses the persistent notification on
///      Android).
///   2. Terminates the application process via [SystemNavigator.pop()] on
///      Android or [exit(0)] on Windows / other platforms.
///
/// After a Quit_Action, wake word detection will not resume until the user
/// manually reopens the application.
///
/// Requirements: 13.2, 13.3, 13.4, 13.5
class QuitAction {
  final IKevinService kevinService;

  const QuitAction({required this.kevinService});

  /// Performs the quit sequence:
  /// - Stops [kevinService] (deactivates Wake_Word_Detector, dismisses
  ///   persistent notification).
  /// - Exits the application process.
  Future<void> perform() async {
    await kevinService.stop();

    if (Platform.isAndroid) {
      await SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}
