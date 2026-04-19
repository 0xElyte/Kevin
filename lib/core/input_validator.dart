import 'exceptions.dart';

const int _maxTextLength = 2000;
const double _minAudioSeconds = 0.5;
const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

const Set<String> _supportedMimeTypes = {
  'image/jpeg',
  'image/png',
  'application/pdf',
  'text/plain',
};

/// Validates a text input message.
///
/// Throws [CharacterLimitError] if [text] exceeds 2000 characters.
/// Returns normally (void) if the text is valid (including empty — callers
/// are responsible for disabling the send button when empty).
void validateTextInput(String text) {
  if (text.length > _maxTextLength) {
    throw CharacterLimitError(
      'Message exceeds $_maxTextLength characters (${text.length} entered).',
    );
  }
}

/// Validates the duration of a captured audio clip.
///
/// Throws [AudioTooShortError] if [duration] is less than 0.5 seconds.
void validateAudioDuration(Duration duration) {
  if (duration.inMicroseconds <
      (_minAudioSeconds * Duration.microsecondsPerSecond).round()) {
    throw AudioTooShortError(
      'Audio clip is too short (${duration.inMilliseconds}ms). Please speak again.',
    );
  }
}

/// Validates a file attachment by MIME type and size.
///
/// Throws [FileTooLargeError] if [sizeBytes] exceeds 10 MB.
/// Throws [UnsupportedFileTypeError] if [mimeType] is not in the supported set.
void validateFileAttachment(String mimeType, int sizeBytes) {
  if (sizeBytes > _maxFileSizeBytes) {
    throw FileTooLargeError(
      'File size (${sizeBytes ~/ (1024 * 1024)} MB) exceeds the 10 MB limit.',
    );
  }
  if (!_supportedMimeTypes.contains(mimeType)) {
    throw UnsupportedFileTypeError(
      'File type "$mimeType" is not supported. '
      'Supported types: image/jpeg, image/png, application/pdf, text/plain.',
    );
  }
}
