import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/models/os_action.dart';
import '../services/intent_router.dart';

/// Windows implementation of [IOSBridge].
///
/// Uses [Process.run] with `cmd /c start` to launch apps and ms-settings: URIs.
/// No platform channels are required — pure Dart via dart:io.
class WindowsOSBridge implements IOSBridge {
  @override
  Future<OSActionResult> openApp(String appName) async {
    try {
      // `start ""` is required so cmd treats the next argument as the target,
      // not the window title.
      final result = await Process.run('cmd', [
        '/c',
        'start',
        '',
        appName,
      ], runInShell: false);
      if (result.exitCode == 0) {
        return const OSActionResult(success: true);
      }
      final stderr = result.stderr as String;
      return OSActionResult(
        success: false,
        errorMessage:
            'Could not open "$appName"'
            '${stderr.isNotEmpty ? ': $stderr' : '.'}',
      );
    } catch (e) {
      return OSActionResult(
        success: false,
        errorMessage: 'Could not open "$appName": ${e.toString()}',
      );
    }
  }

  @override
  Future<OSActionResult> navigateToSettings(SettingsTarget target) async {
    final uri = _settingsUri(target);
    try {
      final result = await Process.run('cmd', [
        '/c',
        'start',
        '',
        uri,
      ], runInShell: false);
      if (result.exitCode == 0) {
        return const OSActionResult(success: true);
      }
      final stderr = result.stderr as String;
      return OSActionResult(
        success: false,
        errorMessage:
            'Could not open settings "$uri"'
            '${stderr.isNotEmpty ? ': $stderr' : '.'}',
      );
    } catch (e) {
      return OSActionResult(
        success: false,
        errorMessage: 'Could not open settings "$uri": ${e.toString()}',
      );
    }
  }

  /// Maps a [SettingsTarget] to the corresponding Windows ms-settings: URI.
  @visibleForTesting
  String settingsUriForTarget(SettingsTarget target) => _settingsUri(target);

  String _settingsUri(SettingsTarget target) {
    switch (target) {
      case SettingsTarget.wifi:
        return 'ms-settings:network-wifi';
      case SettingsTarget.bluetooth:
        return 'ms-settings:bluetooth';
      case SettingsTarget.display:
        return 'ms-settings:display';
      case SettingsTarget.sound:
        return 'ms-settings:sound';
      case SettingsTarget.battery:
        return 'ms-settings:batterysaver';
      case SettingsTarget.storage:
        return 'ms-settings:storagesense';
    }
  }
}
