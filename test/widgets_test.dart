import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

import 'helpers/harness.dart';

void main() {
  setUp(resetCelebrations);
  tearDown(resetCelebrations);

  testWidgets(
      'CelebrationOverlay runs a controller celebration and shakes its '
      'child', (tester) async {
    final controller = CelebrationController();
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: CelebrationOverlay(
        controller: controller,
        child: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => taps++,
              child: const Text('tap'),
            ),
          ),
        ),
      ),
    ));

    final handle =
        controller.celebrate(tier: CelebrationTier.epic, subtitle: 'x2');
    await tester.pump();
    expect(controller.isCelebrating, isTrue);
    var biggest = 0.0;
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (controller.shake.value.distance > biggest) {
        biggest = controller.shake.value.distance;
      }
    }
    expect(biggest, greaterThan(2));
    expect(find.text('EPIC!'), findsNWidgets(2));

    // Touches go through the celebration to the app.
    await tester.tap(find.text('tap'), warnIfMissed: false);
    expect(taps, 1);

    await pumpUntil(tester, () => !handle.isActive);
    expect(controller.isCelebrating, isFalse);
    expect(find.text('EPIC!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CelebrationShaker follows YakoCelebration.show', (tester) async {
    final context = await pumpHost(tester,
        child: const CelebrationShaker(child: Text('content')));
    final before = tester.getTopLeft(find.text('content'));
    YakoCelebration.show(context, tier: CelebrationTier.legendary);
    var moved = false;
    for (var i = 0; i < 40 && !moved; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      final box = tester.renderObject<RenderBox>(find.text('content'));
      final now = box.localToGlobal(Offset.zero);
      moved = (now - before).distance > 1;
    }
    expect(moved, isTrue);
    YakoCelebration.cancelAll();
    await tester.pump();
    final box = tester.renderObject<RenderBox>(find.text('content'));
    expect(box.localToGlobal(Offset.zero), before);
  });

  testWidgets('CelebrationPreview draws any moment without a clock',
      (tester) async {
    for (final tier in CelebrationTier.values) {
      for (final t in <double>[0, 0.2, 0.5, 0.9, 1]) {
        await tester.pumpWidget(MaterialApp(
          home: CelebrationPreview(
            tier: tier,
            progress: AlwaysStoppedAnimation<double>(t),
            subtitle: 'preview',
          ),
        ));
        expect(tester.takeException(), isNull, reason: '$tier at $t');
      }
    }
    await tester.pumpWidget(const MaterialApp(
      home: CelebrationPreview(
        tier: CelebrationTier.epic,
        progress: AlwaysStoppedAnimation<double>(0.3),
        reducedMotion: true,
      ),
    ));
    expect(find.text('EPIC!'), findsNWidgets(2));
  });

  testWidgets('extra layers get the master clock', (tester) async {
    final seen = <double>[];
    final context = await pumpHost(tester);
    final handle = YakoCelebration.show(
      context,
      tier: CelebrationTier.custom(CelebrationConfig(
        duration: const Duration(seconds: 1),
        extraLayers: <CelebrationLayerBuilder>[
          (context, progress) => AnimatedBuilder(
                animation: progress,
                builder: (context, _) {
                  seen.add(progress.value);
                  return const SizedBox(key: ValueKey<String>('mine'));
                },
              ),
        ],
      )),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('mine')), findsOneWidget);
    await pumpUntil(tester, () => !handle.isActive);
    expect(seen.first, 0);
    expect(seen.last, greaterThan(0.9));
  });
}
