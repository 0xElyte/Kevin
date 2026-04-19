// Validates: Requirements 2.2, 2.3
// Tests for Message model: enum values, construction, field access, and copyWith.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:project_kevin/core/models/message.dart';

void main() {
  // ---------------------------------------------------------------------------
  // MessageRole enum
  // ---------------------------------------------------------------------------
  group('MessageRole enum', () {
    test('has user value', () {
      expect(MessageRole.values, contains(MessageRole.user));
    });

    test('has kevin value', () {
      expect(MessageRole.values, contains(MessageRole.kevin));
    });

    test('has exactly 2 values', () {
      expect(MessageRole.values.length, 2);
    });

    test('name of user is "user"', () {
      expect(MessageRole.user.name, 'user');
    });

    test('name of kevin is "kevin"', () {
      expect(MessageRole.kevin.name, 'kevin');
    });
  });

  // ---------------------------------------------------------------------------
  // MessageType enum
  // ---------------------------------------------------------------------------
  group('MessageType enum', () {
    test('has text value', () {
      expect(MessageType.values, contains(MessageType.text));
    });

    test('has voiceNote value', () {
      expect(MessageType.values, contains(MessageType.voiceNote));
    });

    test('has audioGeneration value', () {
      expect(MessageType.values, contains(MessageType.audioGeneration));
    });

    test('has error value', () {
      expect(MessageType.values, contains(MessageType.error));
    });

    test('has exactly 4 values', () {
      expect(MessageType.values.length, 4);
    });

    test('names match expected strings', () {
      expect(MessageType.text.name, 'text');
      expect(MessageType.voiceNote.name, 'voiceNote');
      expect(MessageType.audioGeneration.name, 'audioGeneration');
      expect(MessageType.error.name, 'error');
    });
  });

  // ---------------------------------------------------------------------------
  // MessageStatus enum
  // ---------------------------------------------------------------------------
  group('MessageStatus enum', () {
    test('has sending value', () {
      expect(MessageStatus.values, contains(MessageStatus.sending));
    });

    test('has delivered value', () {
      expect(MessageStatus.values, contains(MessageStatus.delivered));
    });

    test('has error value', () {
      expect(MessageStatus.values, contains(MessageStatus.error));
    });

    test('has exactly 3 values', () {
      expect(MessageStatus.values.length, 3);
    });

    test('names match expected strings', () {
      expect(MessageStatus.sending.name, 'sending');
      expect(MessageStatus.delivered.name, 'delivered');
      expect(MessageStatus.error.name, 'error');
    });
  });

  // ---------------------------------------------------------------------------
  // Message construction and field access
  // ---------------------------------------------------------------------------
  group('Message construction', () {
    final timestamp = DateTime(2024, 1, 15, 10, 30);

    test('constructs a text user message with required fields', () {
      final msg = Message(
        id: 'msg-001',
        role: MessageRole.user,
        type: MessageType.text,
        text: 'Hello Kevin',
        timestamp: timestamp,
        status: MessageStatus.sending,
      );

      expect(msg.id, 'msg-001');
      expect(msg.role, MessageRole.user);
      expect(msg.type, MessageType.text);
      expect(msg.text, 'Hello Kevin');
      expect(msg.timestamp, timestamp);
      expect(msg.status, MessageStatus.sending);
      expect(msg.audioData, isNull);
      expect(msg.audioMimeType, isNull);
    });

    test('constructs a kevin text response', () {
      final msg = Message(
        id: 'msg-002',
        role: MessageRole.kevin,
        type: MessageType.text,
        text: 'Hello! How can I help?',
        timestamp: timestamp,
        status: MessageStatus.delivered,
      );

      expect(msg.role, MessageRole.kevin);
      expect(msg.status, MessageStatus.delivered);
      expect(msg.text, 'Hello! How can I help?');
    });

    test('constructs a voice note message with audio data', () {
      final audio = Uint8List.fromList([0x00, 0x01, 0x02]);
      final msg = Message(
        id: 'msg-003',
        role: MessageRole.user,
        type: MessageType.voiceNote,
        audioData: audio,
        audioMimeType: 'audio/mpeg',
        timestamp: timestamp,
        status: MessageStatus.sending,
      );

      expect(msg.type, MessageType.voiceNote);
      expect(msg.audioData, audio);
      expect(msg.audioMimeType, 'audio/mpeg');
      expect(msg.text, isNull);
    });

    test('constructs an audioGeneration message', () {
      final audio = Uint8List.fromList([0xFF, 0xFB]);
      final msg = Message(
        id: 'msg-004',
        role: MessageRole.kevin,
        type: MessageType.audioGeneration,
        audioData: audio,
        audioMimeType: 'audio/mpeg',
        timestamp: timestamp,
        status: MessageStatus.delivered,
      );

      expect(msg.type, MessageType.audioGeneration);
      expect(msg.role, MessageRole.kevin);
    });

    test('constructs an error message', () {
      final msg = Message(
        id: 'msg-005',
        role: MessageRole.kevin,
        type: MessageType.error,
        text: 'Something went wrong.',
        timestamp: timestamp,
        status: MessageStatus.error,
      );

      expect(msg.type, MessageType.error);
      expect(msg.status, MessageStatus.error);
      expect(msg.text, 'Something went wrong.');
    });
  });

  // ---------------------------------------------------------------------------
  // Message.copyWith
  // ---------------------------------------------------------------------------
  group('Message.copyWith', () {
    final original = Message(
      id: 'orig-001',
      role: MessageRole.user,
      type: MessageType.text,
      text: 'Original text',
      timestamp: DateTime(2024, 1, 1),
      status: MessageStatus.sending,
    );

    test('returns a new instance with updated status', () {
      final updated = original.copyWith(status: MessageStatus.delivered);

      expect(updated.status, MessageStatus.delivered);
      expect(updated.id, original.id);
      expect(updated.role, original.role);
      expect(updated.type, original.type);
      expect(updated.text, original.text);
      expect(updated.timestamp, original.timestamp);
    });

    test('returns a new instance with updated text', () {
      final updated = original.copyWith(text: 'Updated text');

      expect(updated.text, 'Updated text');
      expect(updated.id, original.id);
      expect(updated.status, original.status);
    });

    test('returns a new instance with updated role', () {
      final updated = original.copyWith(role: MessageRole.kevin);

      expect(updated.role, MessageRole.kevin);
      expect(updated.id, original.id);
    });

    test('does not mutate the original message', () {
      original.copyWith(
        status: MessageStatus.error,
        text: 'Changed',
        role: MessageRole.kevin,
      );

      expect(original.status, MessageStatus.sending);
      expect(original.text, 'Original text');
      expect(original.role, MessageRole.user);
    });

    test('copyWith with no arguments returns equivalent message', () {
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.role, original.role);
      expect(copy.type, original.type);
      expect(copy.text, original.text);
      expect(copy.timestamp, original.timestamp);
      expect(copy.status, original.status);
    });

    test('can update audioData and audioMimeType', () {
      final audio = Uint8List.fromList([0xAA, 0xBB]);
      final updated = original.copyWith(
        type: MessageType.voiceNote,
        audioData: audio,
        audioMimeType: 'audio/mpeg',
      );

      expect(updated.type, MessageType.voiceNote);
      expect(updated.audioData, audio);
      expect(updated.audioMimeType, 'audio/mpeg');
    });
  });
}
