// Feature: project-kevin
// Task 2.3: Widget tests verifying SciFi_Theme application to key widgets
// Requirements: 14.1, 14.2, 14.3, 14.4

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_kevin/theme/scifi_theme.dart';
import 'package:project_kevin/theme/scifi_widgets.dart';

/// Wraps a widget in a MaterialApp using SciFiTheme.
Widget withSciFiTheme(Widget child) {
  return MaterialApp(
    theme: SciFiTheme.themeData,
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() {
    // Disable network font fetching during tests — fonts resolve to fallback.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // ---------------------------------------------------------------------------
  // Requirement 14.2 — colorBackground applied to Scaffold
  // ---------------------------------------------------------------------------
  group('colorBackground (Req 14.2)', () {
    testWidgets('Scaffold background is colorBackground (#000000)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final ThemeData resolvedTheme = Theme.of(
        tester.element(find.byType(Scaffold)),
      );
      expect(resolvedTheme.scaffoldBackgroundColor, SciFiTheme.colorBackground);
      expect(resolvedTheme.scaffoldBackgroundColor, const Color(0xFF000000));
      // Scaffold carries no explicit override — inherits from theme.
      expect(scaffold.backgroundColor, isNull);
    });

    testWidgets('AppBar background is colorBackground (#000000)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: Scaffold(
            appBar: AppBar(title: const Text('KEVIN')),
            body: const SizedBox(),
          ),
        ),
      );

      final ThemeData theme = Theme.of(tester.element(find.byType(AppBar)));
      expect(theme.appBarTheme.backgroundColor, SciFiTheme.colorBackground);
      expect(theme.appBarTheme.backgroundColor, const Color(0xFF000000));
    });
  });

  // ---------------------------------------------------------------------------
  // Requirement 14.3 — colorAccent applied to interactive elements
  // ---------------------------------------------------------------------------
  group('colorAccent (Req 14.3)', () {
    testWidgets('SciFiButton (filled) background is colorAccent (#CC0000)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        withSciFiTheme(SciFiButton(text: 'GO', onPressed: () {})),
      );

      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      final bg = elevatedButton.style!.backgroundColor?.resolve(
        <WidgetState>{},
      );
      expect(bg, SciFiTheme.colorAccent);
      expect(bg, const Color(0xFFCC0000));
    });

    testWidgets('SciFiButton (outlined) border color is colorAccent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        withSciFiTheme(
          SciFiButton(text: 'OUTLINED', outlined: true, onPressed: () {}),
        ),
      );

      final outlinedButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      final side = outlinedButton.style!.side?.resolve(<WidgetState>{});
      expect(side?.color, SciFiTheme.colorAccent);
    });

    testWidgets('SciFiCard default border color is colorAccent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        withSciFiTheme(const SciFiCard(child: Text('card'))),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SciFiCard),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, SciFiTheme.colorAccent);
      expect(border.top.color, const Color(0xFFCC0000));
    });

    testWidgets('colorScheme.primary is colorAccent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.colorScheme.primary, SciFiTheme.colorAccent);
      expect(theme.colorScheme.primary, const Color(0xFFCC0000));
    });

    testWidgets('icon theme color is colorAccent', (WidgetTester tester) async {
      await tester.pumpWidget(withSciFiTheme(const Icon(Icons.mic)));

      final theme = Theme.of(tester.element(find.byType(Icon)));
      expect(theme.iconTheme.color, SciFiTheme.colorAccent);
    });
  });

  // ---------------------------------------------------------------------------
  // Requirement 14.4 — Orbitron applied to heading text styles
  // ---------------------------------------------------------------------------
  group('Orbitron font (Req 14.4 — headings)', () {
    testWidgets('displayLarge uses Orbitron font family', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.textTheme.displayLarge?.fontFamily, contains('Orbitron'));
    });

    testWidgets('headlineMedium uses Orbitron font family', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.textTheme.headlineMedium?.fontFamily, contains('Orbitron'));
    });

    testWidgets('titleLarge uses Orbitron font family', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.textTheme.titleLarge?.fontFamily, contains('Orbitron'));
    });

    testWidgets('AppBar title style uses Orbitron font family', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(
        theme.appBarTheme.titleTextStyle?.fontFamily,
        contains('Orbitron'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Requirement 14.4 — Exo 2 applied to body text styles
  //
  // Google Fonts normalises the font family name at runtime:
  //   GoogleFonts.exo2() → fontFamily "Exo2_regular", "Exo2_600", etc.
  // We match the canonical prefix "Exo2" which is always present.
  // ---------------------------------------------------------------------------
  group('Exo 2 font (Req 14.4 — body)', () {
    testWidgets('bodyLarge uses Exo 2 font family', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.textTheme.bodyLarge?.fontFamily, contains('Exo2'));
    });

    testWidgets('bodyMedium uses Exo 2 font family', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.textTheme.bodyMedium?.fontFamily, contains('Exo2'));
    });

    testWidgets('labelLarge uses Exo 2 font family', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.textTheme.labelLarge?.fontFamily, contains('Exo2'));
    });

    testWidgets('SciFiTextField body text style uses Exo 2', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        withSciFiTheme(const SciFiTextField(hintText: 'Type here')),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      // Style is Theme.of(context).textTheme.bodyMedium — Google Fonts
      // normalises "Exo 2" to "Exo2_regular" internally.
      expect(textField.style?.fontFamily, contains('Exo2'));
    });
  });

  // ---------------------------------------------------------------------------
  // Requirement 14.1 / 14.8 — Dark mode forced regardless of system setting
  // ---------------------------------------------------------------------------
  group('Dark mode forced (Req 14.1, 14.8)', () {
    testWidgets('brightness is dark even when platform is in light mode', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('brightness is dark when platform is already dark', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(withSciFiTheme(const SizedBox()));

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.brightness, Brightness.dark);
    });
  });
}
