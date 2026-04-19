import 'package:flutter/material.dart';

import '../../../core/models/message.dart';
import '../../../services/audio_player_service.dart';
import '../../../theme/scifi_theme.dart';

/// A chat bubble for voice notes and audio responses (TTS, Music, SFX).
///
/// Renders a waveform placeholder and a play/pause button. Alignment follows
/// the message role: right for [MessageRole.user], left for [MessageRole.kevin].
///
/// Uses [AudioPlayerService.isPlayingNotifier] to reflect playback state and
/// shows an animated playing indicator while audio is active.
class VoiceNoteBubble extends StatefulWidget {
  final Message message;
  final AudioPlayerService audioPlayerService;

  const VoiceNoteBubble({
    super.key,
    required this.message,
    required this.audioPlayerService,
  });

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isUser => widget.message.role == MessageRole.user;

  Future<void> _onPlayPause(bool isPlaying) async {
    if (isPlaying) {
      await widget.audioPlayerService.stop();
    } else {
      final audioData = widget.message.audioData;
      if (audioData != null) {
        await widget.audioPlayerService.playBytes(audioData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: SciFiTheme.colorSurface,
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          border: _isUser
              ? Border.all(color: SciFiTheme.colorBorderUser, width: 1.0)
              : Border(
                  left: const BorderSide(
                    color: SciFiTheme.colorAccent,
                    width: 3.0,
                  ),
                  top: BorderSide(
                    color: SciFiTheme.colorBorderKevin,
                    width: 1.0,
                  ),
                  right: BorderSide(
                    color: SciFiTheme.colorBorderKevin,
                    width: 1.0,
                  ),
                  bottom: BorderSide(
                    color: SciFiTheme.colorBorderKevin,
                    width: 1.0,
                  ),
                ),
        ),
        padding: SciFiTheme.bubblePadding,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.audioPlayerService.isPlayingNotifier,
          builder: (context, isPlaying, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play/pause button
                IconButton(
                  onPressed: () => _onPlayPause(isPlaying),
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: SciFiTheme.colorAccent,
                    size: 32.0,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8.0),
                // Waveform placeholder
                Expanded(child: _WaveformPlaceholder(isPlaying: isPlaying)),
                // Playing indicator
                if (isPlaying) ...[
                  const SizedBox(width: 8.0),
                  _PlayingIndicator(animation: _pulseAnimation),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A static waveform placeholder rendered as a series of vertical bars.
class _WaveformPlaceholder extends StatelessWidget {
  final bool isPlaying;

  const _WaveformPlaceholder({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    // Fixed bar heights to simulate a waveform pattern
    const barHeights = [
      6.0,
      12.0,
      8.0,
      16.0,
      10.0,
      14.0,
      6.0,
      18.0,
      10.0,
      12.0,
      8.0,
      14.0,
    ];
    final barColor = isPlaying
        ? SciFiTheme.colorAccent
        : SciFiTheme.colorTextSecondary;

    return SizedBox(
      height: 24.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: barHeights
            .map(
              (h) => Container(
                width: 3.0,
                height: h,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// An animated pulsing dot indicator shown while audio is playing.
class _PlayingIndicator extends StatelessWidget {
  final Animation<double> animation;

  const _PlayingIndicator({required this.animation});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        width: 8.0,
        height: 8.0,
        decoration: const BoxDecoration(
          color: SciFiTheme.colorAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
