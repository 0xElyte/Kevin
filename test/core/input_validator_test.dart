// Unit tests for input validation edge cases.
// Requirements: 3.2, 3.3, 4.6, 8.4, 8.5

import 'package:flutter_test/flutter_test.dart';
import 'package:project_kevin/core/input_validator.dart';
import 'package:project_kevin/core/exceptions.dart';

void main() {
  const int maxTextLength = 2000;
  const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  // ---------------------------------------------------------------------------
  // validateTextInput — Requirements 3.2, 3.3
  // ---------------------------------------------------------------------------
  group('validateTextInput', () {
    test('empty string does not throw CharacterLimitError', () {
      // Empty string is allowed by the validator (UI disables send button).
      expect(() => validateTextInput(''), returnsNormally);
    });

    test('single character string is valid', () {
      expect(() => validateTextInput('a'), returnsNormally);
    });

    test('exactly 2000 chars is valid', () {
      final text = 'a' * maxTextLength;
      expect(() => validateTextInput(text), returnsNormally);
    });

    test('exactly 2001 chars throws CharacterLimitError', () {
      final text = 'a' * (maxTextLength + 1);
      expect(
        () => validateTextInput(text),
        throwsA(isA<CharacterLimitError>()),
      );
    });

    test('2001 chars does not throw any other error type', () {
      final text = 'a' * (maxTextLength + 1);
      expect(
        () => validateTextInput(text),
        throwsA(isNot(isA<AudioTooShortError>())),
      );
      expect(
        () => validateTextInput(text),
        throwsA(isNot(isA<FileTooLargeError>())),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // validateAudioDuration — Requirements 4.6
  // ---------------------------------------------------------------------------
  group('validateAudioDuration', () {
    test('exactly 500ms (0.5s) is valid', () {
      expect(
        () => validateAudioDuration(const Duration(milliseconds: 500)),
        returnsNormally,
      );
    });

    test('exactly 499ms throws AudioTooShortError', () {
      expect(
        () => validateAudioDuration(const Duration(milliseconds: 499)),
        throwsA(isA<AudioTooShortError>()),
      );
    });

    test('zero duration throws AudioTooShortError', () {
      expect(
        () => validateAudioDuration(Duration.zero),
        throwsA(isA<AudioTooShortError>()),
      );
    });

    test('duration well above 0.5s is valid', () {
      expect(
        () => validateAudioDuration(const Duration(seconds: 5)),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // validateFileAttachment — Requirements 8.4, 8.5
  // ---------------------------------------------------------------------------
  group('validateFileAttachment', () {
    // Size boundary tests
    test('exactly 10 MB is valid for a supported MIME type', () {
      expect(
        () => validateFileAttachment('image/jpeg', maxFileSizeBytes),
        returnsNormally,
      );
    });

    test('exactly 10 MB + 1 byte throws FileTooLargeError', () {
      expect(
        () => validateFileAttachment('image/jpeg', maxFileSizeBytes + 1),
        throwsA(isA<FileTooLargeError>()),
      );
    });

    // Unsupported MIME type
    test('unsupported MIME type throws UnsupportedFileTypeError', () {
      expect(
        () => validateFileAttachment('video/mp4', 1024),
        throwsA(isA<UnsupportedFileTypeError>()),
      );
    });

    // All 4 supported MIME types are accepted
    test('image/jpeg is accepted', () {
      expect(() => validateFileAttachment('image/jpeg', 1024), returnsNormally);
    });

    test('image/png is accepted', () {
      expect(() => validateFileAttachment('image/png', 1024), returnsNormally);
    });

    test('application/pdf is accepted', () {
      expect(
        () => validateFileAttachment('application/pdf', 1024),
        returnsNormally,
      );
    });

    test('text/plain is accepted', () {
      expect(() => validateFileAttachment('text/plain', 1024), returnsNormally);
    });

    // Size check takes precedence over MIME type check
    test(
      'oversized file with unsupported MIME type throws FileTooLargeError',
      () {
        expect(
          () => validateFileAttachment('video/mp4', maxFileSizeBytes + 1),
          throwsA(isA<FileTooLargeError>()),
        );
      },
    );
  });
}
