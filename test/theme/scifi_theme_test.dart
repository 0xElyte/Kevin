import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_kevin/theme/scifi_theme.dart';

void main() {
  setUpAll(() {
    // Disable font fetching during tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SciFiTheme', () {
    test('color tokens are defined correctly', () {
      expect(SciFiTheme.colorBackground, const Color(0xFF000000));
      expect(SciFiTheme.colorSurface, const Color(0xFF0D0D0D));
      expect(SciFiTheme.colorAccent, const Color(0xFFCC0000));
      expect(SciFiTheme.colorAccentDim, const Color(0xFF660000));
      expect(SciFiTheme.colorTextPrimary, const Color(0xFFFFFFFF));
      expect(SciFiTheme.colorTextSecondary, const Color(0xFF888888));
      expect(SciFiTheme.colorBorderUser, const Color(0xFFCC0000));
      expect(SciFiTheme.colorBorderKevin, const Color(0xFF333333));
    });

    test('layout tokens are defined correctly', () {
      expect(SciFiTheme.borderRadius, 8.0);
      expect(
        SciFiTheme.bubblePadding,
        const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      );
    });

    testWidgets('themeData is always dark', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('themeData uses correct colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.scaffoldBackgroundColor, SciFiTheme.colorBackground);
      expect(theme.colorScheme.primary, SciFiTheme.colorAccent);
      expect(theme.colorScheme.secondary, SciFiTheme.colorAccentDim);
      expect(theme.colorScheme.surface, SciFiTheme.colorSurface);
    });

    testWidgets('theme applies to MaterialApp', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: const Scaffold(body: Text('Test')),
        ),
      );

      final BuildContext context = tester.element(find.text('Test'));
      final theme = Theme.of(context);

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, SciFiTheme.colorBackground);
      expect(theme.colorScheme.primary, SciFiTheme.colorAccent);
    });
  });
}
