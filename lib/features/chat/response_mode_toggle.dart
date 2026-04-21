import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_settings.dart';
import '../../services/settings_service.dart';
import '../../theme/scifi_theme.dart';

/// A compact Voice / Text toggle placed inline in the AppBar.
///
/// Loads the current [ResponseMode] from [SettingsService] on init,
/// persists changes via [SettingsService.saveSettings], and notifies
/// the parent via [onChanged].
class ResponseModeToggle extends StatefulWidget {
  /// Called whenever the user switches the mode.
  final void Function(ResponseMode mode)? onChanged;

  const ResponseModeToggle({super.key, this.onChanged});

  @override
  State<ResponseModeToggle> createState() => _ResponseModeToggleState();
}

class _ResponseModeToggleState extends State<ResponseModeToggle> {
  ResponseMode _mode = ResponseMode.text;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final settings = await SettingsService.instance.loadSettings();
    if (mounted) {
      setState(() {
        _mode = settings.responseMode;
        _loading = false;
      });
    }
  }

  Future<void> _setMode(ResponseMode newMode) async {
    if (newMode == _mode) return;
    setState(() => _mode = newMode);

    // Persist: load current settings, update responseMode, save back.
    final current = await SettingsService.instance.loadSettings();
    await SettingsService.instance.saveSettings(
      current.copyWith(responseMode: newMode),
    );

    widget.onChanged?.call(newMode);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: SciFiTheme.colorAccent,
        ),
      );
    }

    return _SegmentedToggle(selected: _mode, onSelect: _setMode);
  }
}

// ---------------------------------------------------------------------------
// Internal segmented toggle
// ---------------------------------------------------------------------------

class _SegmentedToggle extends StatelessWidget {
  final ResponseMode selected;
  final void Function(ResponseMode) onSelect;

  const _SegmentedToggle({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SciFiTheme.colorSurface,
        borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
        border: Border.all(color: SciFiTheme.colorAccentDim),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Segment(
              label: 'VOICE',
              icon: Icons.mic,
              active: selected == ResponseMode.voice,
              isFirst: true,
              onTap: () => onSelect(ResponseMode.voice),
            ),
            Container(width: 1, color: SciFiTheme.colorAccentDim),
            _Segment(
              label: 'TEXT',
              icon: Icons.chat_bubble_outline,
              active: selected == ResponseMode.text,
              isFirst: false,
              onTap: () => onSelect(ResponseMode.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isFirst;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.active,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = active ? SciFiTheme.colorAccent : Colors.transparent;
    final fgColor = active
        ? SciFiTheme.colorTextPrimary
        : SciFiTheme.colorTextSecondary;

    final radius = BorderRadius.horizontal(
      left: isFirst
          ? const Radius.circular(SciFiTheme.borderRadius - 1)
          : Radius.zero,
      right: !isFirst
          ? const Radius.circular(SciFiTheme.borderRadius - 1)
          : Radius.zero,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: radius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: fgColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: fgColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
