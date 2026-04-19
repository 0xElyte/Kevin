import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/message.dart';
import '../../../theme/scifi_theme.dart';

/// A left-aligned chat bubble for Kevin's messages.
///
/// Renders with a dark background ([SciFiTheme.colorSurface]) and a red left
/// accent border ([SciFiTheme.colorAccent]) using [SciFiTheme] tokens.
///
/// States:
/// - [MessageStatus.sending]: shows pulsating "Kevin is processing..." text
/// - [MessageStatus.error]: shows error text and a retry button
/// - [MessageStatus.delivered]: shows the message text in Exo 2 font
class KevinBubble extends StatefulWidget {
  final Message message;

  /// Called when the user taps the retry button in the error state.
  final VoidCallback? onRetry;

  const KevinBubble({super.key, required this.message, this.onRetry});

  @override
  State<KevinBubble> createState() => _KevinBubbleState();
}

class _KevinBubbleState extends State<KevinBubble>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.message.status == MessageStatus.sending) {
      _initPulseAnimation();
    }
  }

  @override
  void didUpdateWidget(KevinBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.status == MessageStatus.sending &&
        oldWidget.message.status != MessageStatus.sending) {
      _initPulseAnimation();
    } else if (widget.message.status != MessageStatus.sending &&
        oldWidget.message.status == MessageStatus.sending) {
      _disposePulseAnimation();
    }
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  void _disposePulseAnimation() {
    _pulseController?.dispose();
    _pulseController = null;
    _pulseAnimation = null;
  }

  @override
  void dispose() {
    _disposePulseAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: SciFiTheme.colorSurface,
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          border: Border.all(color: SciFiTheme.colorBorderKevin, width: 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 3.0, color: SciFiTheme.colorAccent),
              Flexible(
                child: Padding(
                  padding: SciFiTheme.bubblePadding,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        // Pulsating "Kevin is processing..." text
        if (_pulseAnimation != null) {
          return AnimatedBuilder(
            animation: _pulseAnimation!,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseAnimation!.value,
                child: Text(
                  widget.message.text ?? 'Kevin is processing...',
                  style: GoogleFonts.exo2(
                    color: SciFiTheme.colorAccent,
                    fontSize: 14.0,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            },
          );
        }
        return Text(
          widget.message.text ?? 'Kevin is processing...',
          style: GoogleFonts.exo2(
            color: SciFiTheme.colorAccent,
            fontSize: 14.0,
            fontStyle: FontStyle.italic,
          ),
        );

      case MessageStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.message.text ?? 'An error occurred.',
              style: GoogleFonts.exo2(
                color: SciFiTheme.colorAccent,
                fontSize: 14.0,
              ),
            ),
            if (widget.message.retryable && widget.onRetry != null) ...[
              const SizedBox(height: 8.0),
              GestureDetector(
                onTap: widget.onRetry,
                child: Text(
                  'Retry',
                  style: GoogleFonts.exo2(
                    color: SciFiTheme.colorAccent,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: SciFiTheme.colorAccent,
                  ),
                ),
              ),
            ],
          ],
        );

      case MessageStatus.delivered:
        return Text(
          widget.message.text ?? '',
          style: GoogleFonts.exo2(
            color: SciFiTheme.colorTextPrimary,
            fontSize: 14.0,
          ),
        );
    }
  }
}
