import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/app_settings.dart';

class SettingsService {
  static const String _keyResponseMode = 'response_mode';
  static const String _keyWakeWordEnabled = 'wake_word_enabled';
  static const String _keyWakeWordSensitivity = 'wake_word_sensitivity';
  static const String _keyElevenLabsApiKey = 'eleven_labs_api_key';
  static const String _keyAiApiKey = 'ai_api_key';
  static const String _keyTtsVoiceId = 'tts_voice_id';
  static const String _keyPicovoiceApiKey = 'picovoice_api_key';
  static const String _keyAgentId = 'agent_id';
  static const String _keyTwilioPhoneNumberId = 'twilio_phone_number_id';

  static SettingsService? _instance;

  SettingsService._();

  static SettingsService get instance {
    _instance ??= SettingsService._();
    return _instance!;
  }

  /// Resets the singleton instance. Intended for use in tests only.
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final responseModeStr = prefs.getString(_keyResponseMode);
    final responseMode = responseModeStr == 'voice'
        ? ResponseMode.voice
        : ResponseMode.text;

    return AppSettings(
      responseMode: responseMode,
      wakeWordEnabled: prefs.getBool(_keyWakeWordEnabled) ?? false,
      wakeWordSensitivity: prefs.getDouble(_keyWakeWordSensitivity) ?? 0.5,
      elevenLabsApiKey: prefs.getString(_keyElevenLabsApiKey) ?? '',
      aiApiKey: prefs.getString(_keyAiApiKey) ?? '',
      ttsVoiceId: prefs.getString(_keyTtsVoiceId) ?? '',
      picovoiceApiKey: prefs.getString(_keyPicovoiceApiKey) ?? '',
      agentId: prefs.getString(_keyAgentId) ?? '',
      twilioPhoneNumberId: prefs.getString(_keyTwilioPhoneNumberId) ?? '',
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyResponseMode, settings.responseMode.name);
    await prefs.setBool(_keyWakeWordEnabled, settings.wakeWordEnabled);
    await prefs.setDouble(
      _keyWakeWordSensitivity,
      settings.wakeWordSensitivity,
    );
    await prefs.setString(_keyElevenLabsApiKey, settings.elevenLabsApiKey);
    await prefs.setString(_keyAiApiKey, settings.aiApiKey);
    await prefs.setString(_keyTtsVoiceId, settings.ttsVoiceId);
    await prefs.setString(_keyPicovoiceApiKey, settings.picovoiceApiKey);
    await prefs.setString(_keyAgentId, settings.agentId);
    await prefs.setString(
      _keyTwilioPhoneNumberId,
      settings.twilioPhoneNumberId,
    );
  }
}
