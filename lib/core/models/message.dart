import 'dart:typed_data';

enum MessageRole { user, kevin }

enum MessageType { text, voiceNote, audioGeneration, error }

enum MessageStatus { sending, delivered, error }

class Message {
  final String id;
  final MessageRole role;
  final MessageType type;
  final String? text;
  final Uint8List? audioData;
  final String? audioMimeType;
  final DateTime timestamp;
  final MessageStatus status;

  /// Whether this error message should show a Retry button.
  /// Only true for [TimeoutException] errors per the Error→UI mapping.
  final bool retryable;

  const Message({
    required this.id,
    required this.role,
    required this.type,
    this.text,
    this.audioData,
    this.audioMimeType,
    required this.timestamp,
    required this.status,
    this.retryable = false,
  });

  Message copyWith({
    String? id,
    MessageRole? role,
    MessageType? type,
    String? text,
    Uint8List? audioData,
    String? audioMimeType,
    DateTime? timestamp,
    MessageStatus? status,
    bool? retryable,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      type: type ?? this.type,
      text: text ?? this.text,
      audioData: audioData ?? this.audioData,
      audioMimeType: audioMimeType ?? this.audioMimeType,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      retryable: retryable ?? this.retryable,
    );
  }
}
