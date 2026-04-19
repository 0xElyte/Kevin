// Feature: project-kevin, Property 7: Character Limit Enforced on Text Input
// Validates: Requirements 3.3

import 'package:glados/glados.dart';
import 'package:project_kevin/core/input_validator.dart';
import 'package:project_kevin/core/exceptions.dart';

// ---------------------------------------------------------------------------
// Generators for strings above and below the 2000-char boundary
// ---------------------------------------------------------------------------

extension AnyBoundedString on Any {
  /// Generates a non-empty string with length in [1, 2000].
  Generator<String> get validLengthString => combine2(
    any.intInRange(1, 2001),
    any.letterOrDigits,
    (int len, String base) {
      if (base.isEmpty) base = 'a';
      // Repeat base to reach desired length, then trim.
      final repeated = (base * ((len ~/ base.length) + 1)).substring(0, len);
      return repeated;
    },
  );

  /// Generates a string with length in [2001, 4000].
  Generator<String> get overLimitString => combine2(
    any.intInRange(2001, 4001),
    any.nonEmptyLetterOrDigits,
    (int len, String base) {
      final repeated = (base * ((len ~/ base.length) + 1)).substring(0, len);
      return repeated;
    },
  );
}

// ---------------------------------------------------------------------------
// Property 7: Character Limit Enforced on Text Input
// ---------------------------------------------------------------------------

void main() {
  group('Property 7: Character Limit Enforced on Text Input', () {
    // For any string with length > 2000, validateTextInput throws CharacterLimitError.
    Glados(any.overLimitString, ExploreConfig(numRuns: 100)).test(
      'strings longer than 2000 chars throw CharacterLimitError',
      (text) {
        expect(
          () => validateTextInput(text),
          throwsA(isA<CharacterLimitError>()),
        );
      },
    );

    // For any non-empty string with length ≤ 2000, validateTextInput returns normally.
    Glados(any.validLengthString, ExploreConfig(numRuns: 100)).test(
      'non-empty strings of 2000 chars or fewer are accepted',
      (text) {
        expect(() => validateTextInput(text), returnsNormally);
      },
    );

    // Boundary: exactly 2000 chars is valid.
    test('exactly 2000 chars is accepted', () {
      final text = 'a' * 2000;
      expect(() => validateTextInput(text), returnsNormally);
    });

    // Boundary: exactly 2001 chars throws.
    test('exactly 2001 chars throws CharacterLimitError', () {
      final text = 'a' * 2001;
      expect(
        () => validateTextInput(text),
        throwsA(isA<CharacterLimitError>()),
      );
    });
  });

  _property8Tests();
  _property6Tests();
}

// ---------------------------------------------------------------------------
// Feature: project-kevin, Property 8: File Attachment Constraints Enforced
// Validates: Requirements 8.4, 8.5
// ---------------------------------------------------------------------------

// Supported MIME types (mirrors the set in input_validator.dart)
const List<String> _supportedMimeTypes = [
  'image/jpeg',
  'image/png',
  'application/pdf',
  'text/plain',
];

const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

extension AnyFileAttachment on Any {
  /// Generates a file size strictly greater than 10 MB (up to 20 MB).
  Generator<int> get oversizeBytes =>
      any.intInRange(_maxFileSizeBytes + 1, _maxFileSizeBytes * 2 + 1);

  /// Generates a valid file size in [0, 10 MB].
  Generator<int> get validSizeBytes => any.intInRange(0, _maxFileSizeBytes + 1);

  /// Generates a supported MIME type.
  Generator<String> get supportedMimeType => any
      .intInRange(0, _supportedMimeTypes.length)
      .map((i) => _supportedMimeTypes[i]);

  /// Generates an unsupported MIME type by prepending "x-" to a random
  /// alphanumeric string so it can never collide with the supported set.
  Generator<String> get unsupportedMimeType =>
      any.nonEmptyLetterOrDigits.map((s) => 'x-unsupported/$s');
}

// Property 8 tests — appended to the same file / test runner.
// We use a separate group so they are clearly identified.
void _property8Tests() {
  group('Property 8: File Attachment Constraints Enforced', () {
    // For any size > 10 MB, validateFileAttachment throws FileTooLargeError
    // regardless of MIME type.
    Glados2(
      any.supportedMimeType,
      any.oversizeBytes,
      ExploreConfig(numRuns: 100),
    ).test(
      'files larger than 10 MB throw FileTooLargeError (supported MIME type)',
      (mimeType, sizeBytes) {
        expect(
          () => validateFileAttachment(mimeType, sizeBytes),
          throwsA(isA<FileTooLargeError>()),
        );
      },
    );

    Glados2(
      any.unsupportedMimeType,
      any.oversizeBytes,
      ExploreConfig(numRuns: 100),
    ).test(
      'files larger than 10 MB throw FileTooLargeError (unsupported MIME type)',
      (mimeType, sizeBytes) {
        // Size check happens first — FileTooLargeError takes precedence.
        expect(
          () => validateFileAttachment(mimeType, sizeBytes),
          throwsA(isA<FileTooLargeError>()),
        );
      },
    );

    // For any unsupported MIME type with valid size, throws UnsupportedFileTypeError.
    Glados2(
      any.unsupportedMimeType,
      any.validSizeBytes,
      ExploreConfig(numRuns: 100),
    ).test(
      'unsupported MIME type with valid size throws UnsupportedFileTypeError',
      (mimeType, sizeBytes) {
        expect(
          () => validateFileAttachment(mimeType, sizeBytes),
          throwsA(isA<UnsupportedFileTypeError>()),
        );
      },
    );

    // For any supported MIME type with valid size, the call succeeds.
    Glados2(
      any.supportedMimeType,
      any.validSizeBytes,
      ExploreConfig(numRuns: 100),
    ).test('valid MIME type and valid size are accepted', (
      mimeType,
      sizeBytes,
    ) {
      expect(
        () => validateFileAttachment(mimeType, sizeBytes),
        returnsNormally,
      );
    });

    // Boundary: exactly 10 MB is valid.
    test('exactly 10 MB is accepted', () {
      expect(
        () => validateFileAttachment('image/jpeg', _maxFileSizeBytes),
        returnsNormally,
      );
    });

    // Boundary: exactly 10 MB + 1 byte is rejected.
    test('10 MB + 1 byte throws FileTooLargeError', () {
      expect(
        () => validateFileAttachment('image/jpeg', _maxFileSizeBytes + 1),
        throwsA(isA<FileTooLargeError>()),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Feature: project-kevin, Property 6: Short Audio Clips Are Discarded Without STT Submission
// Validates: Requirements 4.6, 11.8
// ---------------------------------------------------------------------------

extension AnyAudioDuration on Any {
  /// Generates a Duration strictly less than 0.5s (0 to 499ms inclusive).
  Generator<Duration> get shortAudioDuration =>
      any.intInRange(0, 500).map((ms) => Duration(milliseconds: ms));

  /// Generates a Duration at or above 0.5s (500ms to 10s inclusive).
  Generator<Duration> get validAudioDuration =>
      any.intInRange(500, 10001).map((ms) => Duration(milliseconds: ms));
}

// Property 6 tests — appended to the same file / test runner.
void _property6Tests() {
  group('Property 6: Short Audio Clips Are Discarded Without STT Submission', () {
    // For any Duration < 0.5s, validateAudioDuration throws AudioTooShortError.
    Glados(any.shortAudioDuration, ExploreConfig(numRuns: 100)).test(
      'durations below 0.5s throw AudioTooShortError',
      (duration) {
        expect(
          () => validateAudioDuration(duration),
          throwsA(isA<AudioTooShortError>()),
        );
      },
    );

    // For any Duration >= 0.5s, validateAudioDuration returns normally.
    Glados(any.validAudioDuration, ExploreConfig(numRuns: 100)).test(
      'durations at or above 0.5s are accepted',
      (duration) {
        expect(() => validateAudioDuration(duration), returnsNormally);
      },
    );

    // Boundary: exactly 499ms throws.
    test('exactly 499ms throws AudioTooShortError', () {
      expect(
        () => validateAudioDuration(const Duration(milliseconds: 499)),
        throwsA(isA<AudioTooShortError>()),
      );
    });

    // Boundary: exactly 500ms is accepted.
    test('exactly 500ms is accepted', () {
      expect(
        () => validateAudioDuration(const Duration(milliseconds: 500)),
        returnsNormally,
      );
    });

    // Boundary: zero duration throws.
    test('zero duration throws AudioTooShortError', () {
      expect(
        () => validateAudioDuration(Duration.zero),
        throwsA(isA<AudioTooShortError>()),
      );
    });
  });
}
