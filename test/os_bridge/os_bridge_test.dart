// Unit tests for OS_Bridge action mapping
// Requirements: 6.2, 6.3, 6.4, 6.5

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_kevin/core/models/os_action.dart';
import 'package:project_kevin/os_bridge/android_os_bridge.dart';
import 'package:project_kevin/os_bridge/windows_os_bridge.dart';

// ---------------------------------------------------------------------------
// Expected mappings (oracle)
// ---------------------------------------------------------------------------

const Map<SettingsTarget, String> _androidExpected = {
  SettingsTarget.wifi: 'android.settings.WIFI_SETTINGS',
  SettingsTarget.bluetooth: 'android.settings.BLUETOOTH_SETTINGS',
  SettingsTarget.display: 'android.settings.DISPLAY_SETTINGS',
  SettingsTarget.sound: 'android.settings.SOUND_SETTINGS',
  SettingsTarget.battery: 'android.settings.BATTERY_SAVER_SETTINGS',
  SettingsTarget.storage: 'android.settings.INTERNAL_STORAGE_SETTINGS',
};

const Map<SettingsTarget, String> _windowsExpected = {
  SettingsTarget.wifi: 'ms-settings:network-wifi',
  SettingsTarget.bluetooth: 'ms-settings:bluetooth',
  SettingsTarget.display: 'ms-settings:display',
  SettingsTarget.sound: 'ms-settings:sound',
  SettingsTarget.battery: 'ms-settings:batterysaver',
  SettingsTarget.storage: 'ms-settings:storagesense',
};

// ---------------------------------------------------------------------------
// Helpers for mocking the MethodChannel used by AndroidOSBridge
// ---------------------------------------------------------------------------

const _channelName = 'com.projectkevin/os_bridge';

/// Registers a mock handler on the binary messenger for [_channelName].
/// [handler] receives the method name and arguments, and returns the encoded
/// response map (or null to simulate a null response).
void _setMockMethodCallHandler(
  Future<Map<String, dynamic>?> Function(MethodCall call) handler,
) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel(_channelName), (
        call,
      ) async {
        final result = await handler(call);
        return result;
      });
}

void _clearMockMethodCallHandler() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel(_channelName), null);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------------
  // AndroidOSBridge — settingsActionForTarget mapping
  // -------------------------------------------------------------------------

  group('AndroidOSBridge.settingsActionForTarget', () {
    final bridge = AndroidOSBridge();

    for (final target in SettingsTarget.values) {
      test('maps $target to ${_androidExpected[target]}', () {
        expect(
          bridge.settingsActionForTarget(target),
          equals(_androidExpected[target]),
        );
      });
    }

    test('all 6 SettingsTarget values produce android.settings.* strings', () {
      for (final target in SettingsTarget.values) {
        final action = bridge.settingsActionForTarget(target);
        expect(
          action,
          startsWith('android.settings.'),
          reason: 'Expected android.settings.* for $target, got $action',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // WindowsOSBridge — settingsUriForTarget mapping
  // -------------------------------------------------------------------------

  group('WindowsOSBridge.settingsUriForTarget', () {
    final bridge = WindowsOSBridge();

    for (final target in SettingsTarget.values) {
      test('maps $target to ${_windowsExpected[target]}', () {
        expect(
          bridge.settingsUriForTarget(target),
          equals(_windowsExpected[target]),
        );
      });
    }

    test('all 6 SettingsTarget values produce ms-settings: URIs', () {
      for (final target in SettingsTarget.values) {
        final uri = bridge.settingsUriForTarget(target);
        expect(
          uri,
          startsWith('ms-settings:'),
          reason: 'Expected ms-settings: URI for $target, got $uri',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // AndroidOSBridge — openApp
  // -------------------------------------------------------------------------

  group('AndroidOSBridge.openApp', () {
    final bridge = AndroidOSBridge();

    tearDown(_clearMockMethodCallHandler);

    test('success path: returns OSActionResult(success: true)', () async {
      _setMockMethodCallHandler((call) async {
        expect(call.method, equals('openApp'));
        expect(call.arguments['appName'], equals('Spotify'));
        return {'success': true};
      });

      final result = await bridge.openApp('Spotify');

      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('failure path: returns OSActionResult with errorMessage', () async {
      _setMockMethodCallHandler((call) async {
        return {'success': false, 'errorMessage': 'App not found'};
      });

      final result = await bridge.openApp('NonExistentApp');

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('App not found'));
    });

    test('null response from channel returns success=false', () async {
      _setMockMethodCallHandler((call) async => null);

      final result = await bridge.openApp('SomeApp');

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('PlatformException is caught and returned as failure', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(_channelName), (
            call,
          ) async {
            throw PlatformException(
              code: 'UNAVAILABLE',
              message: 'Service unavailable',
            );
          });

      final result = await bridge.openApp('Spotify');

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Spotify'));
    });
  });

  // -------------------------------------------------------------------------
  // AndroidOSBridge — navigateToSettings
  // -------------------------------------------------------------------------

  group('AndroidOSBridge.navigateToSettings', () {
    final bridge = AndroidOSBridge();

    tearDown(_clearMockMethodCallHandler);

    test('success path: sends correct action and returns success', () async {
      String? capturedAction;
      _setMockMethodCallHandler((call) async {
        expect(call.method, equals('navigateToSettings'));
        capturedAction = call.arguments['action'] as String?;
        return {'success': true};
      });

      final result = await bridge.navigateToSettings(SettingsTarget.wifi);

      expect(result.success, isTrue);
      expect(capturedAction, equals('android.settings.WIFI_SETTINGS'));
    });

    test('failure path: returns OSActionResult with errorMessage', () async {
      _setMockMethodCallHandler((call) async {
        return {'success': false, 'errorMessage': 'Settings unavailable'};
      });

      final result = await bridge.navigateToSettings(SettingsTarget.bluetooth);

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Settings unavailable'));
    });

    test('null response from channel returns success=false', () async {
      _setMockMethodCallHandler((call) async => null);

      final result = await bridge.navigateToSettings(SettingsTarget.display);

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('PlatformException is caught and returned as failure', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(_channelName), (
            call,
          ) async {
            throw PlatformException(
              code: 'ERROR',
              message: 'Cannot open settings',
            );
          });

      final result = await bridge.navigateToSettings(SettingsTarget.sound);

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('sends correct action for each SettingsTarget', () async {
      for (final target in SettingsTarget.values) {
        String? capturedAction;
        _setMockMethodCallHandler((call) async {
          capturedAction = call.arguments['action'] as String?;
          return {'success': true};
        });

        await bridge.navigateToSettings(target);

        expect(
          capturedAction,
          equals(_androidExpected[target]),
          reason: 'Wrong action sent for $target',
        );
      }
    });
  });
}
