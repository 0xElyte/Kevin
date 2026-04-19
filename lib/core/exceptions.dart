// Custom exception types for Project Kevin.

class OfflineException implements Exception {
  final String message;
  const OfflineException(this.message);

  @override
  String toString() => 'OfflineException: $message';
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

class STTTranscriptionError implements Exception {
  final String message;
  const STTTranscriptionError(this.message);

  @override
  String toString() => 'STTTranscriptionError: $message';
}

class TTSSynthesisError implements Exception {
  final String message;
  const TTSSynthesisError(this.message);

  @override
  String toString() => 'TTSSynthesisError: $message';
}

class OSActionError implements Exception {
  final String message;
  const OSActionError(this.message);

  @override
  String toString() => 'OSActionError: $message';
}

class FileTooLargeError implements Exception {
  final String message;
  const FileTooLargeError(this.message);

  @override
  String toString() => 'FileTooLargeError: $message';
}

class UnsupportedFileTypeError implements Exception {
  final String message;
  const UnsupportedFileTypeError(this.message);

  @override
  String toString() => 'UnsupportedFileTypeError: $message';
}

class CharacterLimitError implements Exception {
  final String message;
  const CharacterLimitError(this.message);

  @override
  String toString() => 'CharacterLimitError: $message';
}

class AudioTooShortError implements Exception {
  final String message;
  const AudioTooShortError(this.message);

  @override
  String toString() => 'AudioTooShortError: $message';
}

class MusicGenerationError implements Exception {
  final String message;
  const MusicGenerationError(this.message);

  @override
  String toString() => 'MusicGenerationError: $message';
}

class SoundEffectGenerationError implements Exception {
  final String message;
  const SoundEffectGenerationError(this.message);

  @override
  String toString() => 'SoundEffectGenerationError: $message';
}

class AgentSessionError implements Exception {
  final String message;
  const AgentSessionError(this.message);

  @override
  String toString() => 'AgentSessionError: $message';
}

class OutboundCallError implements Exception {
  final String message;
  const OutboundCallError(this.message);

  @override
  String toString() => 'OutboundCallError: $message';
}
