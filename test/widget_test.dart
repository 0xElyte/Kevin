import 'package:flutter_test/flutter_test.dart';
import 'package:project_kevin/main.dart';

void main() {
  testWidgets('Kevin app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KevinApp());
    expect(find.byType(KevinApp), findsOneWidget);
  });
}
