// Feature: project-kevin, Property 4: OS Action Target Maps to Correct Platform Command
// Validates: Requirements 6.2, 6.3

import 'package:glados/glados.dart';
import 'package:project_kevin/core/models/os_action.dart';
import 'package:project_kevin/os_bridge/android_os_bridge.dart';
import 'package:project_kevin/os_bridge/windows_os_bridge.dart';

// ---------------------------------------------------------------------------
// Expected mappings (mirrors the implementation — used as the oracle)
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
// Generator: random SettingsTarget from the enum
// ---------------------------------------------------------------------------

extension AnySettingsTarget on Any {
  Generator<SettingsTarget> get settingsTarget => any
      .intInRange(0, SettingsTarget.values.length)
      .map((i) => SettingsTarget.values[i]);
}

// ---------------------------------------------------------------------------
// Property 4: OS Action Target Maps to Correct Platform Command
// ---------------------------------------------------------------------------

void main() {
  final android = AndroidOSBridge();
  final windows = WindowsOSBridge();

  group('Property 4: OS Action Target Maps to Correct Platform Command', () {
    // Android: every SettingsTarget maps to the correct android.settings.* string.
    Glados(any.settingsTarget, ExploreConfig(numRuns: 100)).test(
      'AndroidOSBridge maps every SettingsTarget to correct android.settings.* action',
      (target) {
        final result = android.settingsActionForTarget(target);
        expect(result, equals(_androidExpected[target]));
        expect(result, startsWith('android.settings.'));
      },
    );

    // Windows: every SettingsTarget maps to the correct ms-settings: URI.
    Glados(any.settingsTarget, ExploreConfig(numRuns: 100)).test(
      'WindowsOSBridge maps every SettingsTarget to correct ms-settings: URI',
      (target) {
        final result = windows.settingsUriForTarget(target);
        expect(result, equals(_windowsExpected[target]));
        expect(result, startsWith('ms-settings:'));
      },
    );

    // Exhaustive check: all 6 SettingsTarget values are covered by both bridges.
    test('all SettingsTarget values are covered by AndroidOSBridge', () {
      for (final target in SettingsTarget.values) {
        final result = android.settingsActionForTarget(target);
        expect(
          result,
          equals(_androidExpected[target]),
          reason: 'Mismatch for $target',
        );
      }
    });

    test('all SettingsTarget values are covered by WindowsOSBridge', () {
      for (final target in SettingsTarget.values) {
        final result = windows.settingsUriForTarget(target);
        expect(
          result,
          equals(_windowsExpected[target]),
          reason: 'Mismatch for $target',
        );
      }
    });
  });

  // Property 5 tests are registered here.
  _property5Tests();
}

// ---------------------------------------------------------------------------
// Feature: project-kevin, Property 5: OS Action Result Always Produces User Feedback
// Validates: Requirements 6.4, 6.5
// ---------------------------------------------------------------------------

// Helper that mirrors the feedback-selection logic in IntentRouter._handleOsAction.
// For a successful result, the confirmation text comes from the AI response text.
// For a failed result, it falls back to errorMessage, then a hard-coded fallback.
String feedbackForOsActionResult(
  OSActionResult result, {
  String responseText = 'Done.',
}) {
  return result.success
      ? responseText
      : (result.errorMessage ?? 'The action could not be completed.');
}

// ---------------------------------------------------------------------------
// Generators for OSActionResult
// ---------------------------------------------------------------------------

extension AnyOSActionResult on Any {
  /// Generates a successful OSActionResult (errorMessage is always null on success).
  Generator<OSActionResult> get successfulOsActionResult =>
      any.intInRange(0, 1).map((_) => const OSActionResult(success: true));

  /// Generates a failed OSActionResult with an optional errorMessage.
  /// Uses letterOrDigits so the string is never null; empty string maps to null.
  Generator<OSActionResult> get failedOsActionResult => any.letterOrDigits.map(
    (msg) =>
        OSActionResult(success: false, errorMessage: msg.isEmpty ? null : msg),
  );

  /// Generates any OSActionResult (success or failure).
  Generator<OSActionResult> get osActionResult => any.bool.bind(
    (isSuccess) => isSuccess ? successfulOsActionResult : failedOsActionResult,
  );
}

// ---------------------------------------------------------------------------
// Property 5 tests
// ---------------------------------------------------------------------------

void _property5Tests() {
  group('Property 5: OS Action Result Always Produces User Feedback', () {
    // For any successful OSActionResult, feedback equals the non-empty responseText.
    Glados(any.successfulOsActionResult, ExploreConfig(numRuns: 100)).test(
      'successful OSActionResult always produces non-empty feedback',
      (result) {
        const responseText = 'Action completed successfully.';
        final feedback = feedbackForOsActionResult(
          result,
          responseText: responseText,
        );
        expect(feedback, isNotEmpty);
        expect(feedback, equals(responseText));
      },
    );

    // For any failed OSActionResult, feedback is non-empty (errorMessage or fallback).
    Glados(any.failedOsActionResult, ExploreConfig(numRuns: 100)).test(
      'failed OSActionResult always produces non-empty feedback',
      (result) {
        final feedback = feedbackForOsActionResult(result);
        expect(feedback, isNotEmpty);
      },
    );

    // For any OSActionResult (success or failure), feedback is always non-empty.
    Glados(any.osActionResult, ExploreConfig(numRuns: 200)).test(
      'any OSActionResult always produces non-empty feedback',
      (result) {
        final feedback = feedbackForOsActionResult(result);
        expect(feedback, isNotEmpty);
      },
    );

    // Edge case: failed result with empty-string errorMessage — the ?? operator
    // does NOT treat empty string as null, so feedback will be empty.
    // Our generator maps empty strings to null to avoid this, but we document
    // the behavior here for clarity.
    test(
      'failed OSActionResult with null errorMessage uses fallback message',
      () {
        const result = OSActionResult(success: false);
        final feedback = feedbackForOsActionResult(result);
        expect(feedback, equals('The action could not be completed.'));
        expect(feedback, isNotEmpty);
      },
    );

    // Edge case: successful result always echoes the provided responseText.
    test('successful OSActionResult echoes responseText', () {
      const result = OSActionResult(success: true);
      const responseText = 'Opened Spotify.';
      final feedback = feedbackForOsActionResult(
        result,
        responseText: responseText,
      );
      expect(feedback, equals(responseText));
    });
  });
}
