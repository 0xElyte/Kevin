import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_settings.dart';
import '../../theme/scifi_theme.dart';
import 'response_mode_toggle.dart';

/// SciFi-styled AppBar for Project Kevin.
///
/// Layout: [KEVIN title] — [ResponseModeToggle] — [Quit ✕]
///
/// Implements [PreferredSizeWidget] so it can be used directly as
/// [Scaffold.appBar].
class KevinAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Called when the user switches between Voice and Text response modes.
  final void Function(ResponseMode)? onResponseModeChanged;

  /// Called when the user taps the Quit (✕) button.
  final VoidCallback onQuit;

  /// Optional callback for navigating to the settings screen.
  final VoidCallback? onSettingsPressed;

  const KevinAppBar({
    super.key,
    this.onResponseModeChanged,
    required this.onQuit,
    this.onSettingsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: SciFiTheme.colorBackground,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'KEVIN',
        style: GoogleFonts.orbitron(
          color: SciFiTheme.colorAccent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
      ),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'AI RESPONSE TYPE',
              style: GoogleFonts.orbitron(
                color: SciFiTheme.colorTextSecondary,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            ResponseModeToggle(onChanged: onResponseModeChanged),
          ],
        ),
        const SizedBox(width: 4),
        if (onSettingsPressed != null)
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: SciFiTheme.colorTextPrimary,
            ),
            tooltip: 'Settings',
            onPressed: onSettingsPressed,
          ),
        IconButton(
          icon: const Icon(Icons.close, color: SciFiTheme.colorTextPrimary),
          tooltip: 'Quit',
          onPressed: onQuit,
        ),
      ],
    );
  }
}
