import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

import 'helpers/harness.dart';

// A 1×1 transparent PNG.
final Uint8List _pixel = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  setUp(resetCelebrations);
  tearDown(resetCelebrations);

  testWidgets('runs for the tier length, then cleans up', (tester) async {
    final context = await pumpHost(tester);
    var completed = 0;
    final handle = YakoCelebration.show(
      context,
      tier: CelebrationTier.great,
      onComplete: () => completed++,
      seed: 1,
    );
    var finished = false;
    unawaited(handle.done.then((_) => finished = true));

    await tester.pump();
    expect(handle.isActive, isTrue);
    expect(YakoCelebration.isCelebrating, isTrue);
    expect(find.text('Great!'), findsNWidgets(2), reason: 'outline + fill');

    await tester.pump(const Duration(milliseconds: 3300));
    expect(handle.isActive, isTrue, reason: 'great lasts 3.4 s');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(handle.isActive, isFalse);
    expect(finished, isTrue);
    expect(completed, 1);
    expect(YakoCelebration.isCelebrating, isFalse);
    expect(find.text('Great!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel removes it at once and skips onComplete', (tester) async {
    final context = await pumpHost(tester);
    var completed = false;
    final handle = YakoCelebration.show(context,
        tier: CelebrationTier.epic, onComplete: () => completed = true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('EPIC!'), findsNWidgets(2), reason: 'outline + fill');
    handle.cancel();
    await tester.pump();
    expect(find.text('EPIC!'), findsNothing);
    expect(handle.isActive, isFalse);
    await tester.pump(const Duration(seconds: 6));
    expect(completed, isFalse);
  });

  testWidgets('a new celebration replaces the one on screen', (tester) async {
    final context = await pumpHost(tester);
    final first = YakoCelebration.show(context, tier: CelebrationTier.epic);
    await tester.pump(const Duration(milliseconds: 300));
    final second = YakoCelebration.show(context, tier: CelebrationTier.nice);
    await tester.pump();
    expect(first.isActive, isFalse);
    expect(second.isActive, isTrue);
    expect(find.text('EPIC!'), findsNothing);
    expect(find.text('Nice!'), findsNWidgets(2), reason: 'outline + fill');

    final third = YakoCelebration.show(context,
        tier: CelebrationTier.subtle, exclusive: false);
    await tester.pump();
    expect(second.isActive, isTrue);
    expect(third.isActive, isTrue);
    YakoCelebration.cancelAll();
    await tester.pump();
    expect(YakoCelebration.isCelebrating, isFalse);
  });

  testWidgets('title and subtitle can change while it runs', (tester) async {
    final context = await pumpHost(tester);
    final handle = YakoCelebration.show(context,
        tier: CelebrationTier.epic, title: 'Level 5', subtitle: '+100 XP');
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Level 5'), findsNWidgets(2), reason: 'outline + fill');
    expect(find.text('+100 XP'), findsOneWidget);
    handle
      ..updateSubtitle('+250 XP')
      ..updateTitle('Level 6');
    await tester.pump();
    expect(find.text('+250 XP'), findsOneWidget);
    expect(find.text('Level 6'), findsNWidgets(2), reason: 'outline + fill');
    expect(handle.subtitle, '+250 XP');
    handle.cancel();
  });

  testWidgets('an empty title hides the title', (tester) async {
    final context = await pumpHost(tester);
    YakoCelebration.show(context, tier: CelebrationTier.epic, title: '');
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('EPIC!'), findsNothing);
    YakoCelebration.cancelAll();
  });

  testWidgets('a custom config is respected', (tester) async {
    final context = await pumpHost(tester);
    var done = false;
    YakoCelebration.show(
      context,
      tier: const CelebrationTier.custom(CelebrationConfig(
        duration: Duration(seconds: 2),
        effects: <CelebrationEffect>[CoinsEffect(count: 12)],
      )),
      onComplete: () => done = true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Text), findsOneWidget, reason: 'only the host text');
    await tester.pump(const Duration(milliseconds: 1400));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 150));
    expect(done, isTrue);
  });

  testWidgets('a title without a title effect still slams in', (tester) async {
    final context = await pumpHost(tester);
    YakoCelebration.show(
      context,
      tier: const CelebrationTier.custom(CelebrationConfig(
        title: 'Custom!',
        effects: <CelebrationEffect>[ConfettiEffect(count: 10)],
      )),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Custom!'), findsNWidgets(2), reason: 'outline + fill');
    YakoCelebration.cancelAll();
  });

  testWidgets('reduced motion shows the short calm version', (tester) async {
    final context = await pumpHost(tester, reducedMotion: true);
    final shakes = <Offset>[];
    void listener() => shakes.add(YakoCelebration.shake.value);
    YakoCelebration.shake.addListener(listener);
    addTearDown(() => YakoCelebration.shake.removeListener(listener));

    final handle =
        YakoCelebration.show(context, tier: CelebrationTier.legendary);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('LEGENDARY!'), findsNWidgets(2), reason: 'outline + fill');
    final took = await pumpUntil(tester, () => !handle.isActive);
    expect(took, lessThanOrEqualTo(const Duration(milliseconds: 850)),
        reason: 'at most 1.4 s in total');
    expect(shakes.where((o) => o != Offset.zero), isEmpty);
  });

  testWidgets('the brand icon pops up', (tester) async {
    final context = await pumpHost(tester);
    YakoCelebration.show(
      context,
      tier: CelebrationTier.epic,
      brand: const CelebrationBrand(
        name: 'Acme',
        icon: SizedBox(key: ValueKey<String>('logo'), width: 10, height: 10),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    final pops = CelebrationTier.epic.config.effectsOf<BrandPopEffect>().single;
    // Every pop plus the badge.
    expect(find.byKey(const ValueKey<String>('logo')),
        findsNWidgets(pops.count + 1));
    expect(find.text('Acme'), findsOneWidget, reason: 'brand badge');
    YakoCelebration.cancelAll();
  });

  testWidgets('an image brand and the app-wide brand work', (tester) async {
    YakoCelebration.configure(
      preloadSounds: false,
      brand: CelebrationBrand(name: 'Pixel', image: MemoryImage(_pixel)),
    );
    final context = await pumpHost(tester);
    YakoCelebration.show(context, tier: CelebrationTier.legendary);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Pixel'), findsOneWidget);
    YakoCelebration.cancelAll();
  });

  testWidgets('haptics follow the pattern, and can be turned off',
      (tester) async {
    final calls = recordHaptics(tester);
    final context = await pumpHost(tester);
    final handle = YakoCelebration.show(context, tier: CelebrationTier.epic);
    await pumpUntil(tester, () => !handle.isActive);
    expect(calls, hasLength(CelebrationTier.epic.config.haptics.pulses.length));
    expect(
        calls.first, 'HapticFeedback.vibrate:HapticFeedbackType.heavyImpact');

    calls.clear();
    YakoCelebration.hapticsEnabled = false;
    final quiet = YakoCelebration.show(context, tier: CelebrationTier.epic);
    await pumpUntil(tester, () => !quiet.isActive);
    expect(calls, isEmpty);
  });

  testWidgets('the screen shakes on the hit and settles', (tester) async {
    final context = await pumpHost(tester);
    final handle = YakoCelebration.show(context, tier: CelebrationTier.epic);
    var biggest = 0.0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      biggest = biggest > YakoCelebration.shake.value.distance
          ? biggest
          : YakoCelebration.shake.value.distance;
    }
    expect(biggest, greaterThan(2));
    await pumpUntil(tester, () => !handle.isActive);
    expect(YakoCelebration.shake.value, Offset.zero);
  });

  testWidgets('no exceptions over full runs at many screen sizes',
      (tester) async {
    const sizes = <Size>[
      Size(320, 480),
      Size(390, 844),
      Size(844, 390),
      Size(1024, 1366),
      Size(1920, 1080),
      Size(120, 120),
    ];
    for (final size in sizes) {
      final context = await pumpHost(tester, size: size);
      for (final tier in CelebrationTier.values) {
        final handle = YakoCelebration.show(context,
            tier: tier, subtitle: 'NEW RECORD', seed: size.width.toInt());
        await pumpUntil(tester, () => !handle.isActive,
            step: const Duration(milliseconds: 90));
        expect(handle.isActive, isFalse, reason: '$tier at $size');
        expect(tester.takeException(), isNull, reason: '$tier at $size');
      }
    }
  });

  testWidgets('works with slow motion (timeDilation)', (tester) async {
    final context = await pumpHost(tester);
    timeDilation = 4;
    addTearDown(() => timeDilation = 1);
    final handle = YakoCelebration.show(context, tier: CelebrationTier.nice);
    await tester.pump(const Duration(milliseconds: 4000));
    expect(handle.isActive, isTrue, reason: '2.2 s × 4 is 8.8 s');
    await pumpUntil(tester, () => !handle.isActive);
    expect(handle.isActive, isFalse);
    timeDilation = 1;
  });

  testWidgets('show() without an Overlay explains what to do', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }),
    ));
    expect(() => YakoCelebration.show(context), throwsFlutterError);
  });
}
