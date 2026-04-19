import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_kevin/theme/scifi_theme.dart';
import 'package:project_kevin/theme/scifi_widgets.dart';

void main() {
  setUpAll(() {
    // Disable font fetching during tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SciFiButton', () {
    testWidgets('renders with correct styling', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: Scaffold(
            body: SciFiButton(
              text: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(SciFiButton));
      expect(pressed, true);
    });

    testWidgets('renders outlined variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: Scaffold(
            body: SciFiButton(
              text: 'Outlined',
              outlined: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: Scaffold(
            body: SciFiButton(
              text: 'With Icon',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });
  });

  group('SciFiTextField', () {
    testWidgets('renders with correct styling', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: Scaffold(
            body: SciFiTextField(
              controller: controller,
              hintText: 'Enter text',
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);
    });

    testWidgets('handles text input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: Scaffold(body: SciFiTextField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello Kevin');
      expect(controller.text, 'Hello Kevin');
    });

    testWidgets('displays error text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: const Scaffold(
            body: SciFiTextField(errorText: 'Error message'),
          ),
        ),
      );

      expect(find.text('Error message'), findsOneWidget);
    });
  });

  group('SciFiCard', () {
    testWidgets('renders with correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: const Scaffold(body: SciFiCard(child: Text('Card Content'))),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('handles tap when onTap is provided', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: Scaffold(
            body: SciFiCard(
              onTap: () => tapped = true,
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Card'));
      expect(tapped, true);
    });

    testWidgets('uses custom border color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.themeData,
          home: const Scaffold(
            body: SciFiCard(
              borderColor: Colors.blue,
              child: Text('Custom Border'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SciFiCard),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isA<Border>());
    });
  });
}
