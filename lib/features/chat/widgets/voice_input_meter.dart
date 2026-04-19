import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../theme/scifi_theme.dart';

/// A circular arc meter that visualises the current RMS audio level.
///
/// The sweep angle of the arc maps linearly from 0 (silent) to a full circle
/// (maximum level). The widget drives its own animation at 60 fps via a
/// [Ticker] so callers only need to update [rmsLevel] and the repaint happens
/// automatically.
///
/// Styled with [SciFiTheme] tokens: red ([SciFiTheme.colorAccent]) ring on a
/// black ([SciFiTheme.colorBackground]) background.
///
/// Requirements: 11.4, 14.6
class VoiceInputMeter extends StatefulWidget {
  /// Current RMS audio level in the range [0.0, 1.0].
  final double rmsLevel;

  /// Diameter of the meter widget.
  final double size;

  /// Width of the arc stroke.
  final double strokeWidth;

  const VoiceInputMeter({
    super.key,
    required this.rmsLevel,
    this.size = 64.0,
    this.strokeWidth = 4.0,
  });

  @override
  State<VoiceInputMeter> createState() => _VoiceInputMeterState();
}

class _VoiceInputMeterState extends State<VoiceInputMeter>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  /// Smoothed level used for rendering — interpolated toward [widget.rmsLevel]
  /// each frame so the animation feels fluid rather than jumpy.
  double _smoothedLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    // Lerp toward the target level at ~10 units/second for smooth animation.
    const double lerpSpeed = 0.15;
    final double target = widget.rmsLevel.clamp(0.0, 1.0);
    final double next = _smoothedLevel + (target - _smoothedLevel) * lerpSpeed;
    if ((next - _smoothedLevel).abs() > 0.001) {
      setState(() {
        _smoothedLevel = next;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _VoiceInputMeterPainter(
          level: _smoothedLevel,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

/// [CustomPainter] that draws the circular arc for [VoiceInputMeter].
///
/// The arc starts at the top of the circle (−π/2) and sweeps clockwise by
/// `level * 2π` radians, where `level` is in [0.0, 1.0].
class _VoiceInputMeterPainter extends CustomPainter {
  final double level;
  final double strokeWidth;

  const _VoiceInputMeterPainter({
    required this.level,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track ring (dim red).
    final trackPaint = Paint()
      ..color = SciFiTheme.colorAccentDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active arc (bright red), sweeps proportionally to the RMS level.
    if (level > 0.0) {
      final arcPaint = Paint()
        ..color = SciFiTheme.colorAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      // Start at the top (−90°) and sweep clockwise.
      const double startAngle = -math.pi / 2;
      final double sweepAngle = level.clamp(0.0, 1.0) * 2 * math.pi;

      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_VoiceInputMeterPainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.strokeWidth != strokeWidth;
}
