import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yako_celebrations_example/main.dart';

void main() {
  testWidgets('gallery lists both styles and celebrates on tap',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Subtle'), findsOneWidget);
    expect(find.text('Legendary'), findsOneWidget);

    await tester.tap(find.text('Nice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Nice!'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Nice!'), findsNothing);

    await tester.tap(find.text('Lottie'));
    await tester.pump();
    await tester.tap(find.text('Great'));
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);

    // The code card shows the tier that just played.
    await tester.scrollUntilVisible(
      find.textContaining('CelebrationTier.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('CelebrationTier.lottieGreat'), findsOneWidget);
  });

  testWidgets('playground builds and previews', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Playground'));
    await tester.pumpAndSettle();
    expect(find.text('Celebrate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
