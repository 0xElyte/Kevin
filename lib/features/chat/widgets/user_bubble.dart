import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/message.dart';
import '../../../theme/scifi_theme.dart';

/// A right-aligned chat bubble for user messages.
///
/// Renders the text content of a [Message] with a red border
/// using [SciFiTheme.colorBorderUser] and Exo 2 body font.
class UserBubble extends StatelessWidget {
  final Message message;

  const UserBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: SciFiTheme.bubblePadding,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: SciFiTheme.colorSurface,
          borderRadius: BorderRadius.circular(SciFiTheme.borderRadius),
          border: Border.all(color: SciFiTheme.colorBorderUser, width: 1.0),
        ),
        child: Text(
          message.text ?? '',
          style: GoogleFonts.exo2(
            color: SciFiTheme.colorTextPrimary,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }
}
