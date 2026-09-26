import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart' show Lottie, LottieComposition;
import 'package:yako_celebrations/src/engine/lottie_layer.dart';
import 'package:yako_celebrations/src/presets.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

double _maxShake(CelebrationConfig c) =>
    c.effectsOf<ShakeEffect>().fold(0.0, (m, e) => math.max(m, e.strength));

double _maxFlash(CelebrationConfig c) =>
    c.effectsOf<FlashEffect>().fold(0.0, (m, e) => math.max(m, e.strength));

double _vignette(CelebrationConfig c) =>
    c.effectsOf<EdgeGlowEffect>().fold(0.0, (m, e) => math.max(m, e.strength));

/// A [frames] / 30 s, 100 × 100 Lottie file with nothing in it.
Future<LottieComposition> _blank([int frames = 60]) =>
    LottieComposition.fromBytes(Uint8List.fromList(
        utf8.encode('{"v":"5.7.4","fr":30,"ip":0,"op":$frames,"w":100,"h":100,'
            '"layers":[]}')));

void main() {
  final timings = jsonDecode(File('tool/sound_timings.json').readAsStringSync())
      as Map<String, dynamic>;
  const ladder = CelebrationTier.lottieValues;

  test('the Lottie ladder is in order and separate from the code-drawn one',
      () {
    expect(ladder.map((t) => t.name), <String>[
      'lottie_subtle',
      'lottie_nice',
      'lottie_great',
      'lottie_epic',
      'lottie_legendary',
    ]);
    for (var i = 0; i < ladder.length; i++) {
      expect(ladder[i].level, i);
      expect(ladder[i].isLottie, isTrue);
      expect(ladder[i].isCustom, isFalse);
      expect(CelebrationTier.values[i].isLottie, isFalse);
      expect(ladder[i], isNot(CelebrationTier.values[i]));
      expect(ladder[i].config.effectsOf<LottieEffect>(), isNotEmpty);
    }
  });

  test('each Lottie tier is longer and bigger than the one below', () {
    for (var i = 1; i < ladder.length; i++) {
      final lower = ladder[i - 1].config;
      final upper = ladder[i].config;
      final label = '${ladder[i - 1].name} -> ${ladder[i].name}';
      expect(upper.duration, greaterThan(lower.duration), reason: label);
      expect(upper.effectsOf<LottieEffect>().length,
          greaterThanOrEqualTo(lower.effectsOf<LottieEffect>().length),
          reason: label);
      expect(_vignette(upper), greaterThan(_vignette(lower)), reason: label);
      expect(_maxShake(upper), greaterThan(_maxShake(lower)), reason: label);
      expect(_maxFlash(upper), greaterThan(_maxFlash(lower)), reason: label);
      expect(upper.effectsOf<TitleSlamEffect>().single.slamFrom,
          greaterThan(lower.effectsOf<TitleSlamEffect>().single.slamFrom),
          reason: label);
      expect(upper.haptics.pulses.length,
          greaterThanOrEqualTo(lower.haptics.pulses.length),
          reason: label);
    }
  });

  test('every Lottie tier window is inside the celebration', () {
    for (final tier in ladder) {
      for (final effect in tier.config.effects) {
        expect(effect.start, inInclusiveRange(0, 1),
            reason: '${tier.name} $effect');
        expect(effect.end, inInclusiveRange(effect.start, 1),
            reason: '${tier.name} $effect');
      }
      for (final pulse in tier.config.haptics.pulses) {
        expect(pulse.at, inInclusiveRange(0, 1));
      }
    }
  });

  test('Lottie tier sounds ship with the package and match the timing', () {
    for (final tier in ladder) {
      final config = tier.config;
      final sound = config.sound! as BuiltInCelebrationSound;
      expect(sound.tier, tier);
      expect(sound.assetKey,
          'packages/yako_celebrations/assets/sounds/${tier.name}.mp3');
      final file = File('assets/sounds/${tier.name}.mp3');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.lengthSync(), greaterThan(4000));

      final spec = timings[tier.name] as Map<String, dynamic>;
      expect(
          config.seconds, closeTo((spec['duration'] as num).toDouble(), 1e-6),
          reason: '${tier.name} length');
      final title = config.effectsOf<TitleSlamEffect>().single;
      expect(title.start * config.seconds + title.impactDelay,
          closeTo((spec['impact'] as num).toDouble(), 0.02),
          reason: '${tier.name} title lands on the hit');
      expect(lottieImpactSeconds, (spec['impact'] as num).toDouble());
    }
  });

  test('every bundled Lottie file ships, with its licence', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/lottie/'));
    final licence = File('assets/lottie/LICENSE.md').readAsStringSync();
    expect(licence, contains('Lottie Simple License'));
    for (final animation in CelebrationLottie.values) {
      final name = '${animation.file}.lottie';
      final file = File('assets/lottie/$name');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.lengthSync(), greaterThan(1000), reason: file.path);
      expect(licence, contains('`$name`'), reason: 'credit for $name');
      expect(
          animation.assetKey, 'packages/yako_celebrations/assets/lottie/$name');
    }
  });

  test('every bundled Lottie file parses', () async {
    for (final animation in CelebrationLottie.values) {
      final bytes =
          File('assets/lottie/${animation.file}.lottie').readAsBytesSync();
      final composition = await LottieComposition.fromBytes(bytes);
      expect(composition.seconds, greaterThan(0.3), reason: animation.name);
      expect(composition.bounds.width, greaterThan(0), reason: animation.name);
    }
  });

  test('your own Lottie file gets the right asset key', () {
    expect(const LottieEffect.asset('assets/a.json').assetKey, 'assets/a.json');
    expect(const LottieEffect.asset('assets/a.json', package: 'p').assetKey,
        'packages/p/assets/a.json');
  });

  test('anchors follow the screen', () {
    const size = Size(400, 800);
    Rect rect(LottieAnchor anchor, double scale) => lottieRectFor(
        LottieEffect(CelebrationLottie.confetti, anchor: anchor, scale: scale),
        size);
    expect(rect(LottieAnchor.fullScreen, 1), Offset.zero & size);
    expect(
        rect(LottieAnchor.topBand, 0.4), const Rect.fromLTWH(0, 0, 400, 320));
    expect(rect(LottieAnchor.bottomEdge, 0.5),
        const Rect.fromLTWH(0, 600, 400, 200));
    expect(rect(LottieAnchor.topLeft, 0.5).width, 200);
    expect(rect(LottieAnchor.topLeft, 0.5).left, lessThan(0));
    expect(rect(LottieAnchor.topRight, 0.5).right, greaterThan(400));
    expect(rect(LottieAnchor.center, 0.5).center.dx, 200);
  });

  group('playing', () {
    setUp(CelebrationLottieCache.clear);
    tearDown(CelebrationLottieCache.clear);

    Future<void> pumpAt(WidgetTester tester, CelebrationTier tier, double t) =>
        tester.pumpWidget(MaterialApp(
          home: CelebrationPreview(
            tier: tier,
            progress: AlwaysStoppedAnimation<double>(t),
          ),
        ));

    double opacity(WidgetTester tester) => tester
        .widget<FadeTransition>(find.descendant(
            of: find.byType(LottieLayer),
            matching: find.byType(FadeTransition)))
        .opacity
        .value;

    testWidgets('a Lottie layer follows the celebration clock', (tester) async {
      final blank = await tester.runAsync(_blank);
      CelebrationLottieCache.put('mine.json', blank!);
      const tier = CelebrationTier.custom(CelebrationConfig(
        duration: Duration(seconds: 4),
        effects: <CelebrationEffect>[
          LottieEffect.asset('mine.json',
              anchor: LottieAnchor.center, loop: false, start: 0.25),
        ],
      ));

      await pumpAt(tester, tier, 0.1);
      expect(find.byType(Lottie), findsOneWidget);
      expect(opacity(tester), 0, reason: 'before its window');

      await pumpAt(tester, tier, 0.5);
      expect(opacity(tester), 1, reason: '1 s into a 2 s file');
      final frame = tester.widget<Lottie>(find.byType(Lottie)).controller!;
      expect(frame.value, closeTo(0.5, 1e-3));

      await pumpAt(tester, tier, 0.9);
      expect(opacity(tester), 0, reason: 'a one-shot file has ended');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a layer switches file when the celebration changes',
        (tester) async {
      final first = await tester.runAsync(_blank);
      final second = await tester.runAsync(() => _blank(90));
      CelebrationLottieCache.put('a.json', first!);
      CelebrationLottieCache.put('b.json', second!);
      CelebrationTier tier(String path) =>
          CelebrationTier.custom(CelebrationConfig(
              duration: const Duration(seconds: 2),
              effects: <CelebrationEffect>[LottieEffect.asset(path)]));

      await pumpAt(tester, tier('a.json'), 0.5);
      expect(tester.widget<Lottie>(find.byType(Lottie)).composition, first);
      await pumpAt(tester, tier('b.json'), 0.5);
      expect(tester.widget<Lottie>(find.byType(Lottie)).composition, second);
    });

    testWidgets('a file that is still loading draws nothing', (tester) async {
      await pumpAt(tester, CelebrationTier.lottieEpic, 0.3);
      expect(find.byType(LottieLayer), findsWidgets);
      expect(find.byType(Lottie), findsNothing);
      expect(find.text('MASSIVE'), findsWidgets);
    });

    test('reduced motion keeps the title but drops the animations', () {
      final calm = CelebrationTier.lottieLegendary.config.toReducedMotion();
      expect(calm.effectsOf<LottieEffect>(), isEmpty);
      expect(calm.effectsOf<ShakeEffect>(), isEmpty);
      final title = calm.effectsOf<TitleSlamEffect>().single;
      expect(title.colors, isNotNull);
      expect(title.shimmer, isFalse);
    });
  });
}
