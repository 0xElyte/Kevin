import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/models/os_action.dart';
import '../services/intent_router.dart';

/// Android implementation of [IOSBridge].
///
/// Communicates with the native Android side via a [MethodChannel].
/// The native side uses PackageManager for app lookup and android.settings.*
/// intents for settings navigation.
class AndroidOSBridge implements IOSBridge {
  static const _channel = MethodChannel('com.projectkevin/os_bridge');

  @override
  Future<OSActionResult> openApp(String appName) async {
    try {
      final result = await _channel.invokeMethod<Map>('openApp', {
        'appName': appName,
      });
      if (result == null) {
        return const OSActionResult(
          success: false,
          errorMessage: 'No response from native bridge.',
        );
      }
      final success = result['success'] as bool? ?? false;
      final errorMessage = result['errorMessage'] as String?;
      return OSActionResult(success: success, errorMessage: errorMessage);
    } on PlatformException catch (e) {
      return OSActionResult(
        success: false,
        errorMessage: 'Could not open "$appName": ${e.message}',
      );
    }
  }

  @override
  Future<OSActionResult> navigateToSettings(SettingsTarget target) async {
    final action = _settingsAction(target);
    try {
      final result = await _channel.invokeMethod<Map>('navigateToSettings', {
        'action': action,
      });
      if (result == null) {
        return const OSActionResult(
          success: false,
          errorMessage: 'No response from native bridge.',
        );
      }
      final success = result['success'] as bool? ?? false;
      final errorMessage = result['errorMessage'] as String?;
      return OSActionResult(success: success, errorMessage: errorMessage);
    } on PlatformException catch (e) {
      return OSActionResult(
        success: false,
        errorMessage: 'Could not open settings: ${e.message}',
      );
    }
  }

  /// Maps a [SettingsTarget] to the corresponding Android settings intent action.
  @visibleForTesting
  String settingsActionForTarget(SettingsTarget target) =>
      _settingsAction(target);

  String _settingsAction(SettingsTarget target) {
    switch (target) {
      case SettingsTarget.wifi:
        return 'android.settings.WIFI_SETTINGS';
      case SettingsTarget.bluetooth:
        return 'android.settings.BLUETOOTH_SETTINGS';
      case SettingsTarget.display:
        return 'android.settings.DISPLAY_SETTINGS';
      case SettingsTarget.sound:
        return 'android.settings.SOUND_SETTINGS';
      case SettingsTarget.battery:
        return 'android.settings.BATTERY_SAVER_SETTINGS';
      case SettingsTarget.storage:
        return 'android.settings.INTERNAL_STORAGE_SETTINGS';
    }
  }
}
