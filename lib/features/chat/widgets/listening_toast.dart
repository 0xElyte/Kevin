import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/scifi_theme.dart';
import 'voice_input_meter.dart';

/// An overlay widget that indicates Kevin is actively listening.
///
/// Displays a SciFi-styled card with the label "Kevin is listening..." and a
/// [VoiceInputMeter] that pulses with the current microphone RMS level.
///
/// ## System overlay (background use)
/// When the app is in the background, the host [Kevin_Service] raises this
/// widget via the `flutter_foreground_task` overlay API by calling
/// `FlutterForegroundTask.showOverlayNotification` / the overlay entry point.
/// Within the app foreground, it is inserted as a full-screen [Stack] overlay
/// using Flutter's [Overlay] widget.
///
/// Requirements: 11.3, 12.4, 14.6
class ListeningToast extends StatelessWidget {
  /// Current RMS audio level forwarded to [VoiceInputMeter] (0.0–1.0).
  final double rmsLevel;

  /// Called when the toast should be dismissed (e.g. after STT submission).
  final VoidCallback? onDismiss;

  const ListeningToast({super.key, this.rmsLevel = 0.0, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color: SciFiTheme.colorSurface,
            borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
            border: Border.all(color: SciFiTheme.colorAccent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: SciFiTheme.colorAccent.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated voice input meter
              VoiceInputMeter(rmsLevel: rmsLevel, size: 72, strokeWidth: 5),
              const SizedBox(height: 16),
              // "Kevin is listening..." label
              Text(
                'Kevin is listening...',
                style: GoogleFonts.orbitron(
                  color: SciFiTheme.colorTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper that inserts a [ListeningToast] into the nearest [Overlay].
///
/// Returns an [OverlayEntry] that the caller must remove when the toast should
/// be dismissed (e.g. after STT submission).
///
/// Usage:
/// ```dart
/// final entry = ListeningToastOverlay.show(context, rmsLevel: _rmsLevel);
/// // … later …
/// entry.remove();
/// ```
class ListeningToastOverlay {
  ListeningToastOverlay._();

  /// Shows the [ListeningToast] as a full-screen overlay.
  ///
  /// [rmsLevelNotifier] is a [ValueNotifier] whose value is forwarded to the
  /// meter so the overlay can be updated without rebuilding the whole tree.
  static OverlayEntry show(
    BuildContext context, {
    ValueNotifier<double>? rmsLevelNotifier,
  }) {
    final notifier = rmsLevelNotifier ?? ValueNotifier(0.0);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ValueListenableBuilder<double>(
        valueListenable: notifier,
        builder: (_, level, child) =>
            ListeningToast(rmsLevel: level, onDismiss: entry.remove),
      ),
    );

    Overlay.of(context).insert(entry);
    return entry;
  }
}
