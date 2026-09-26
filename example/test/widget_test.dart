import 'package:flutter_test/flutter_test.dart';
import 'package:yako_celebrations_example/main.dart';

void main() {
  testWidgets('gallery lists every tier and celebrates on tap', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('subtle'), findsOneWidget);
    await tester.tap(find.text('nice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Nice!'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Nice!'), findsNothing);
  });

  testWidgets('playground builds and previews', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Playground'));
    await tester.pumpAndSettle();
    expect(find.text('Celebrate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
