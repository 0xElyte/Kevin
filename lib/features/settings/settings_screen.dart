import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/wake_word/i_kevin_service.dart';
import '../../features/wake_word/kevin_service.dart';
import '../../services/settings_service.dart';
import '../../theme/scifi_theme.dart';

/// Settings screen for Project Kevin.
///
/// Allows the user to configure:
/// - ElevenLabs API key
/// - AI API key
/// - Wake word enable/disable (starts/stops Kevin_Service)
/// - Wake word sensitivity (0.0–1.0)
/// - TTS voice ID
///
/// All fields persist via [SettingsService].
/// Requirements: 12.2, 12.6
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService.instance;
  late final IKevinService _kevinService;

  final _elevenLabsKeyController = TextEditingController();
  final _aiApiKeyController = TextEditingController();
  final _ttsVoiceIdController = TextEditingController();
  final _agentIdController = TextEditingController();
  final _twilioPhoneNumberIdController = TextEditingController();

  bool _wakeWordEnabled = false;
  double _wakeWordSensitivity = 0.5;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _kevinService = createKevinService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    if (!mounted) return;
    setState(() {
      _elevenLabsKeyController.text = settings.elevenLabsApiKey;
      _aiApiKeyController.text = settings.aiApiKey;
      _ttsVoiceIdController.text = settings.ttsVoiceId;
      _agentIdController.text = settings.agentId;
      _twilioPhoneNumberIdController.text = settings.twilioPhoneNumberId;
      _wakeWordEnabled = settings.wakeWordEnabled;
      _wakeWordSensitivity = settings.wakeWordSensitivity;
      _isLoading = false;
    });
  }

  Future<void> _saveField() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final current = await _settingsService.loadSettings();
      await _settingsService.saveSettings(
        current.copyWith(
          elevenLabsApiKey: _elevenLabsKeyController.text.trim(),
          aiApiKey: _aiApiKeyController.text.trim(),
          ttsVoiceId: _ttsVoiceIdController.text.trim(),
          agentId: _agentIdController.text.trim(),
          twilioPhoneNumberId: _twilioPhoneNumberIdController.text.trim(),
          wakeWordEnabled: _wakeWordEnabled,
          wakeWordSensitivity: _wakeWordSensitivity,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleWakeWordToggle(bool value) async {
    setState(() => _wakeWordEnabled = value);
    if (value) {
      await _kevinService.start();
    } else {
      await _kevinService.stop();
    }
    await _saveField();
  }

  Future<void> _handleSensitivityChanged(double value) async {
    setState(() => _wakeWordSensitivity = value);
    await _saveField();
  }

  @override
  void dispose() {
    _elevenLabsKeyController.dispose();
    _aiApiKeyController.dispose();
    _ttsVoiceIdController.dispose();
    _agentIdController.dispose();
    _twilioPhoneNumberIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SciFiTheme.colorBackground,
      appBar: AppBar(
        backgroundColor: SciFiTheme.colorBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: SciFiTheme.colorAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.orbitron(
            color: SciFiTheme.colorAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SciFiTheme.colorAccent),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(title: 'API KEYS'),
                const SizedBox(height: 12),
                _ApiKeyField(
                  label: 'ElevenLabs API Key',
                  controller: _elevenLabsKeyController,
                  onEditingComplete: _saveField,
                ),
                const SizedBox(height: 12),
                _ApiKeyField(
                  label: 'AI API Key',
                  controller: _aiApiKeyController,
                  onEditingComplete: _saveField,
                ),
                const SizedBox(height: 12),
                _ApiKeyField(
                  label: 'TTS Voice ID',
                  controller: _ttsVoiceIdController,
                  onEditingComplete: _saveField,
                  obscureText: false,
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'ELEVENLABS AGENT'),
                const SizedBox(height: 12),
                _ApiKeyField(
                  label: 'Agent ID',
                  controller: _agentIdController,
                  onEditingComplete: _saveField,
                  obscureText: false,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Create an agent at elevenlabs.io/app/conversational-ai',
                    style: GoogleFonts.exo2(
                      color: SciFiTheme.colorTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'OUTBOUND CALLS (TWILIO)'),
                const SizedBox(height: 12),
                _ApiKeyField(
                  label: 'Twilio Phone Number ID',
                  controller: _twilioPhoneNumberIdController,
                  onEditingComplete: _saveField,
                  obscureText: false,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Link a Twilio number in ElevenLabs dashboard to enable outbound calls.',
                    style: GoogleFonts.exo2(
                      color: SciFiTheme.colorTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'WAKE WORD'),
                const SizedBox(height: 12),
                _WakeWordToggle(
                  enabled: _wakeWordEnabled,
                  onChanged: _handleWakeWordToggle,
                ),
                const SizedBox(height: 16),
                _SensitivitySlider(
                  value: _wakeWordSensitivity,
                  enabled: _wakeWordEnabled,
                  onChanged: _handleSensitivityChanged,
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.orbitron(
        color: SciFiTheme.colorAccent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 3,
      ),
    );
  }
}

class _ApiKeyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onEditingComplete;
  final bool obscureText;

  const _ApiKeyField({
    required this.label,
    required this.controller,
    required this.onEditingComplete,
    this.obscureText = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.exo2(color: SciFiTheme.colorTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.exo2(color: SciFiTheme.colorTextSecondary),
        filled: true,
        fillColor: SciFiTheme.colorSurface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          borderSide: const BorderSide(color: SciFiTheme.colorAccentDim),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          borderSide: const BorderSide(color: SciFiTheme.colorAccent, width: 2),
        ),
      ),
      onEditingComplete: onEditingComplete,
    );
  }
}

class _WakeWordToggle extends StatelessWidget {
  final bool enabled;
  final Future<void> Function(bool) onChanged;

  const _WakeWordToggle({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SciFiTheme.colorSurface,
        borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
        border: Border.all(color: SciFiTheme.colorAccentDim),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wake Word Detection',
                style: GoogleFonts.exo2(
                  color: SciFiTheme.colorTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Say "Hey Kevin" to activate',
                style: GoogleFonts.exo2(
                  color: SciFiTheme.colorTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: SciFiTheme.colorAccent,
            inactiveThumbColor: SciFiTheme.colorTextSecondary,
            inactiveTrackColor: SciFiTheme.colorAccentDim,
          ),
        ],
      ),
    );
  }
}

class _SensitivitySlider extends StatelessWidget {
  final double value;
  final bool enabled;
  final Future<void> Function(double) onChanged;

  const _SensitivitySlider({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SciFiTheme.colorSurface,
        borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
        border: Border.all(
          color: enabled ? SciFiTheme.colorAccentDim : SciFiTheme.colorSurface,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wake Word Sensitivity',
                style: GoogleFonts.exo2(
                  color: enabled
                      ? SciFiTheme.colorTextPrimary
                      : SciFiTheme.colorTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: GoogleFonts.orbitron(
                  color: enabled
                      ? SciFiTheme.colorAccent
                      : SciFiTheme.colorTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: SciFiTheme.colorAccent,
              inactiveTrackColor: SciFiTheme.colorAccentDim,
              thumbColor: SciFiTheme.colorAccent,
              overlayColor: SciFiTheme.colorAccent.withAlpha(30),
              disabledActiveTrackColor: SciFiTheme.colorTextSecondary,
              disabledInactiveTrackColor: SciFiTheme.colorSurface,
              disabledThumbColor: SciFiTheme.colorTextSecondary,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: enabled ? onChanged : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: GoogleFonts.exo2(
                  color: SciFiTheme.colorTextSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                'High',
                style: GoogleFonts.exo2(
                  color: SciFiTheme.colorTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
