import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

void main() {
  group('CelebrationConfig', () {
    test('copyWith keeps what it is not given', () {
      final epic = CelebrationTier.epic.config;
      final copy =
          epic.copyWith(title: 'Streak!', color: const Color(0xFF00FF00));
      expect(copy.title, 'Streak!');
      expect(copy.color, const Color(0xFF00FF00));
      expect(copy.duration, epic.duration);
      expect(copy.effects, same(epic.effects));
      expect(copy.sound, epic.sound);
      expect(copy.haptics, epic.haptics);
      expect(copy.backgroundDim, epic.backgroundDim);
    });

    test('without and withEffects edit the effect list', () {
      final epic = CelebrationTier.epic.config;
      final calm = epic.without<ShakeEffect>().without<FlashEffect>();
      expect(calm.effectsOf<ShakeEffect>(), isEmpty);
      expect(calm.effectsOf<FlashEffect>(), isEmpty);
      expect(calm.effects.length, epic.effects.length - 2,
          reason: 'epic has one shake and one flash');
      final more =
          calm.withEffects(const <CelebrationEffect>[FireWallEffect()]);
      expect(more.effectsOf<FireWallEffect>(), hasLength(1));
    });

    test('particleCount adds up the effects', () {
      const config = CelebrationConfig(effects: <CelebrationEffect>[
        CoinsEffect(count: 10),
        ConfettiEffect(count: 20),
        FireworksEffect(shells: 2, sparks: 9),
      ]);
      expect(config.particleCount, 10 + 20 + 2 * 10);
    });

    test('reduced motion is short and calm', () {
      for (final tier in CelebrationTier.values) {
        final calm = tier.config.toReducedMotion();
        expect(calm.seconds, lessThanOrEqualTo(1.4), reason: tier.name);
        for (final effect in calm.effects) {
          expect(
            effect,
            anyOf(isA<TitleSlamEffect>(), isA<SparklesEffect>(),
                isA<EdgeGlowEffect>()),
            reason: '${tier.name}: $effect should not move much',
          );
        }
        for (final title in calm.effectsOf<TitleSlamEffect>()) {
          expect(title.slamFrom, 1, reason: 'no slam');
        }
        for (final sparkles in calm.effectsOf<SparklesEffect>()) {
          expect(sparkles.count, lessThanOrEqualTo(10));
        }
        expect(calm.haptics.pulses.length, lessThanOrEqualTo(1));
        expect(calm.sound, tier.config.sound, reason: 'sound stays');
        expect(calm.title, tier.config.title);
      }
    });

    test('a hand-made reduced-motion version wins', () {
      const quiet = CelebrationConfig(duration: Duration(milliseconds: 500));
      const config = CelebrationConfig(
        effects: <CelebrationEffect>[FlamesEffect()],
        reducedMotion: quiet,
      );
      expect(config.toReducedMotion(), same(quiet));
    });
  });

  group('CelebrationPalette', () {
    test('accent resolves to shades of the colour', () {
      const color = Color(0xFF3366FF);
      final resolved = CelebrationPalette.accent.resolve(color);
      expect(resolved.colors.first, color);
      expect(resolved.colors.length, greaterThan(1));
      expect(CelebrationPalette.accent.representative(color), color);
      expect(CelebrationPalette.gold.resolve(color), CelebrationPalette.gold);
    });

    test('rainbow cycles hues', () {
      expect(CelebrationPalette.rainbow.cycleHues, isTrue);
      expect(CelebrationPalette.gold.cycleHues, isFalse);
    });

    test('equality is by value', () {
      expect(
        const CelebrationPalette(<Color>[Color(0xFF000000)]),
        const CelebrationPalette(<Color>[Color(0xFF000000)]),
      );
      expect(CelebrationPalette.gold, isNot(CelebrationPalette.fire));
    });
  });

  group('effects', () {
    test('title impact follows the slam', () {
      const slam = TitleSlamEffect(slamDuration: 1);
      expect(slam.impactDelay, closeTo(0.19, 1e-9));
      const fade = TitleSlamEffect(slamFrom: 1);
      expect(fade.impactDelay, 0);
    });

    test('windows outside 0..1 are rejected', () {
      expect(() => CoinsEffect(start: -0.1), throwsA(isA<AssertionError>()));
      expect(() => CoinsEffect(end: 1.2), throwsA(isA<AssertionError>()));
      expect(() => CoinsEffect(start: 0.6, end: 0.5),
          throwsA(isA<AssertionError>()));
    });
  });
}
