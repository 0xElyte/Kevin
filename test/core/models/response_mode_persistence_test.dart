// Feature: project-kevin, Property 3: ResponseMode Persists Across Restarts
// Validates: Requirements 5.4

import 'package:glados/glados.dart';
import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_kevin/core/models/app_settings.dart';

// ---------------------------------------------------------------------------
// Minimal inline stub for SettingsService persistence of ResponseMode.
// This will be replaced by the real SettingsService once task 4.1 is done.
// ---------------------------------------------------------------------------

const _kResponseModeKey = 'response_mode';

/// Writes [mode] to [prefs].
Future<void> writeResponseMode(SharedPreferences prefs, ResponseMode mode) {
  return prefs.setString(_kResponseModeKey, mode.name);
}

/// Reads [ResponseMode] from [prefs]. Returns [ResponseMode.voice] as default.
ResponseMode readResponseMode(SharedPreferences prefs) {
  final raw = prefs.getString(_kResponseModeKey);
  if (raw == null) return ResponseMode.voice;
  return ResponseMode.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => ResponseMode.voice,
  );
}

// ---------------------------------------------------------------------------
// Generator for ResponseMode enum values
// ---------------------------------------------------------------------------

extension AnyResponseMode on Any {
  Generator<ResponseMode> get responseMode => choose(ResponseMode.values);
}

// ---------------------------------------------------------------------------
// Property test
// ---------------------------------------------------------------------------

void main() {
  group('Property 3: ResponseMode Persists Across Restarts', () {
    // Property-based test: for any ResponseMode value, writing then reading
    // back (simulating a restart via SharedPreferences mock) returns the same value.
    Glados(
      any.responseMode,
      ExploreConfig(numRuns: 100),
    ).test('round-trip persistence returns the same ResponseMode', (
      mode,
    ) async {
      // Simulate a fresh app start with empty storage.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Write the mode (simulates user setting preference).
      await writeResponseMode(prefs, mode);

      // Simulate app restart: obtain a new SharedPreferences instance.
      // The mock retains values across getInstance() calls within the same test.
      final prefsAfterRestart = await SharedPreferences.getInstance();
      final readBack = readResponseMode(prefsAfterRestart);

      expect(readBack, equals(mode));
    });

    // Concrete examples for each enum value (unit-test style complement).
    test('voice mode persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await writeResponseMode(prefs, ResponseMode.voice);
      expect(
        readResponseMode(await SharedPreferences.getInstance()),
        ResponseMode.voice,
      );
    });

    test('text mode persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await writeResponseMode(prefs, ResponseMode.text);
      expect(
        readResponseMode(await SharedPreferences.getInstance()),
        ResponseMode.text,
      );
    });

    test('default is voice when no value stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(readResponseMode(prefs), ResponseMode.voice);
    });
  });
}
