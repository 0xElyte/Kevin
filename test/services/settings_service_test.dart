import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_kevin/services/settings_service.dart';
import 'package:project_kevin/core/models/app_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService', () {
    test('loadSettings returns defaults when no values stored', () async {
      final settings = await SettingsService.instance.loadSettings();

      expect(settings.responseMode, ResponseMode.text);
      expect(settings.wakeWordEnabled, false);
      expect(settings.wakeWordSensitivity, 0.5);
      expect(settings.elevenLabsApiKey, '');
      expect(settings.aiApiKey, '');
      expect(settings.ttsVoiceId, '');
    });

    test(
      'saveSettings persists all fields and loadSettings reads them back',
      () async {
        const saved = AppSettings(
          responseMode: ResponseMode.voice,
          wakeWordEnabled: true,
          wakeWordSensitivity: 0.8,
          elevenLabsApiKey: 'el-key-123',
          aiApiKey: 'ai-key-456',
          ttsVoiceId: 'voice-abc',
        );

        await SettingsService.instance.saveSettings(saved);
        final loaded = await SettingsService.instance.loadSettings();

        expect(loaded.responseMode, ResponseMode.voice);
        expect(loaded.wakeWordEnabled, true);
        expect(loaded.wakeWordSensitivity, 0.8);
        expect(loaded.elevenLabsApiKey, 'el-key-123');
        expect(loaded.aiApiKey, 'ai-key-456');
        expect(loaded.ttsVoiceId, 'voice-abc');
      },
    );

    test('saveSettings overwrites previous values', () async {
      const first = AppSettings(
        responseMode: ResponseMode.voice,
        wakeWordEnabled: true,
        wakeWordSensitivity: 0.9,
        elevenLabsApiKey: 'old-key',
        aiApiKey: 'old-ai',
        ttsVoiceId: 'old-voice',
      );
      const second = AppSettings(
        responseMode: ResponseMode.text,
        wakeWordEnabled: false,
        wakeWordSensitivity: 0.3,
        elevenLabsApiKey: 'new-key',
        aiApiKey: 'new-ai',
        ttsVoiceId: 'new-voice',
      );

      await SettingsService.instance.saveSettings(first);
      await SettingsService.instance.saveSettings(second);
      final loaded = await SettingsService.instance.loadSettings();

      expect(loaded.responseMode, ResponseMode.text);
      expect(loaded.wakeWordEnabled, false);
      expect(loaded.wakeWordSensitivity, 0.3);
      expect(loaded.elevenLabsApiKey, 'new-key');
    });

    test('instance returns the same singleton', () {
      expect(SettingsService.instance, same(SettingsService.instance));
    });
  });
}
