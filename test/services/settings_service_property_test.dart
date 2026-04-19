// Feature: project-kevin, Property 3: ResponseMode Persists Across Restarts
// Validates: Requirements 5.4

import 'package:glados/glados.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_kevin/core/models/app_settings.dart';
import 'package:project_kevin/services/settings_service.dart';

// ---------------------------------------------------------------------------
// Generator for ResponseMode enum values
// ---------------------------------------------------------------------------

extension AnyResponseMode on Any {
  Generator<ResponseMode> get responseMode => choose(ResponseMode.values);
}

// ---------------------------------------------------------------------------
// Property 3: ResponseMode Persists Across Restarts
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Reset the singleton so each test gets a fresh SettingsService instance.
    SettingsService.resetInstance();
  });

  group('Property 3: ResponseMode Persists Across Restarts', () {
    // For any ResponseMode value, writing it via SettingsService then reading
    // it back via a new SettingsService instance (simulating an app restart)
    // must return the same value.
    Glados(any.responseMode, ExploreConfig(numRuns: 100)).test(
      'round-trip via SettingsService returns the same ResponseMode',
      (mode) async {
        // Write the mode using the first SettingsService instance.
        final settingsToSave = AppSettings(
          responseMode: mode,
          wakeWordEnabled: false,
          wakeWordSensitivity: 0.5,
          elevenLabsApiKey: '',
          aiApiKey: '',
          ttsVoiceId: '',
        );
        await SettingsService.instance.saveSettings(settingsToSave);

        // Simulate restart: reset singleton so a new instance is created.
        SettingsService.resetInstance();

        // Read back via the new instance.
        final loaded = await SettingsService.instance.loadSettings();

        expect(loaded.responseMode, equals(mode));
      },
    );

    test('voice mode persists across restart', () async {
      await SettingsService.instance.saveSettings(
        const AppSettings(
          responseMode: ResponseMode.voice,
          wakeWordEnabled: false,
          wakeWordSensitivity: 0.5,
          elevenLabsApiKey: '',
          aiApiKey: '',
          ttsVoiceId: '',
        ),
      );

      SettingsService.resetInstance();
      final loaded = await SettingsService.instance.loadSettings();
      expect(loaded.responseMode, ResponseMode.voice);
    });

    test('text mode persists across restart', () async {
      await SettingsService.instance.saveSettings(
        const AppSettings(
          responseMode: ResponseMode.text,
          wakeWordEnabled: false,
          wakeWordSensitivity: 0.5,
          elevenLabsApiKey: '',
          aiApiKey: '',
          ttsVoiceId: '',
        ),
      );

      SettingsService.resetInstance();
      final loaded = await SettingsService.instance.loadSettings();
      expect(loaded.responseMode, ResponseMode.text);
    });
  });
}
