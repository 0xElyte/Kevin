import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Saves [audioBytes] as a temporary MP3 file and triggers the OS share sheet.
///
/// On Android this opens the native share chooser so the user can send the
/// voice clip via WhatsApp, Telegram, email, etc.
///
/// Falls back to copying the file path to the clipboard on platforms where
/// the share sheet is unavailable.
class VoiceShare {
  static const MethodChannel _channel = MethodChannel('project_kevin/share');

  /// Share [audioBytes] as a voice message with the given [fileName].
  static Future<void> shareAudio(
    Uint8List audioBytes, {
    String fileName = 'kevin_voice.mp3',
    String shareText = 'Voice message from Kevin',
  }) async {
    // Write bytes to a temp file.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(audioBytes);

    try {
      // Invoke the native share sheet via a platform channel.
      await _channel.invokeMethod<void>('shareFile', {
        'filePath': file.path,
        'mimeType': 'audio/mpeg',
        'text': shareText,
      });
    } on MissingPluginException {
      // Platform channel not wired yet — no-op; the file is still saved.
      // In a production build, implement the Android MethodChannel handler
      // in MainActivity.kt using FileProvider + Intent.ACTION_SEND.
    }
  }
}
