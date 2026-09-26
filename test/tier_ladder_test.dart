import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:yako_celebrations/src/presets.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

double _maxShake(CelebrationConfig c) =>
    c.effectsOf<ShakeEffect>().fold(0.0, (m, e) => math.max(m, e.strength));

double _maxFlash(CelebrationConfig c) =>
    c.effectsOf<FlashEffect>().fold(0.0, (m, e) => math.max(m, e.strength));

double _maxPop(CelebrationConfig c) =>
    c.effectsOf<BrandPopEffect>().fold(0.0, (m, e) => math.max(m, e.maxSize));

Set<Type> _kinds(CelebrationConfig c) =>
    c.effects.map((e) => e.runtimeType).toSet();

void main() {
  final timings = jsonDecode(File('tool/sound_timings.json').readAsStringSync())
      as Map<String, dynamic>;

  test('ready-made tiers are in order', () {
    expect(CelebrationTier.values.map((t) => t.name),
        <String>['subtle', 'nice', 'great', 'epic', 'legendary']);
    for (var i = 0; i < CelebrationTier.values.length; i++) {
      expect(CelebrationTier.values[i].level, i);
      expect(CelebrationTier.values[i].isCustom, isFalse);
    }
  });

  test('each tier is longer and bigger than the one below', () {
    final tiers = CelebrationTier.values;
    for (var i = 1; i < tiers.length; i++) {
      final lower = tiers[i - 1].config;
      final upper = tiers[i].config;
      final label = '${tiers[i - 1].name} -> ${tiers[i].name}';
      expect(upper.duration, greaterThan(lower.duration), reason: label);
      expect(upper.particleCount, greaterThan(lower.particleCount),
          reason: label);
      expect(_kinds(upper).length, greaterThanOrEqualTo(_kinds(lower).length),
          reason: label);
      expect(upper.backgroundDim, greaterThanOrEqualTo(lower.backgroundDim),
          reason: label);
      expect(_maxShake(upper), greaterThanOrEqualTo(_maxShake(lower)),
          reason: label);
      expect(_maxFlash(upper), greaterThanOrEqualTo(_maxFlash(lower)),
          reason: label);
      expect(_maxPop(upper), greaterThanOrEqualTo(_maxPop(lower)),
          reason: label);
      expect(upper.haptics.pulses.length,
          greaterThanOrEqualTo(lower.haptics.pulses.length),
          reason: label);
    }
  });

  test('subtle is a quick sparkle', () {
    final c = CelebrationTier.subtle.config;
    expect(c.seconds, lessThanOrEqualTo(1.5));
    expect(c.effectsOf<SparklesEffect>(), isNotEmpty);
    expect(c.effectsOf<ShakeEffect>(), isEmpty);
    expect(c.effectsOf<FlashEffect>(), isEmpty);
    expect(c.title, isNull);
  });

  test('legendary has everything', () {
    final c = CelebrationTier.legendary.config;
    expect(c.seconds, inInclusiveRange(6, 8));
    expect(
      c.effectsOf<FlamesEffect>().where((e) => e.palette?.cycleHues ?? false),
      isNotEmpty,
      reason: 'rainbow flames',
    );
    expect(c.effectsOf<FireWallEffect>(), isNotEmpty);
    expect(c.effectsOf<FireworksEffect>(), isNotEmpty);
    expect(c.effectsOf<CoinsEffect>(), isNotEmpty);
    expect(_maxPop(c), greaterThanOrEqualTo(0.8), reason: 'giant brand pop');
    expect(_maxFlash(c), greaterThan(0.5));
    expect(_maxShake(c), greaterThan(10));
  });

  test('every effect window is inside the celebration', () {
    for (final tier in CelebrationTier.values) {
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

  test('each tier plays its own built-in sound, which ships with the package',
      () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/sounds/'));
    for (final tier in CelebrationTier.values) {
      final sound = tier.config.sound;
      expect(sound, isA<BuiltInCelebrationSound>());
      sound as BuiltInCelebrationSound;
      expect(sound.tier, tier);
      expect(sound.assetKey,
          'packages/yako_celebrations/assets/sounds/${tier.name}.mp3');
      final file = File('assets/sounds/${tier.name}.mp3');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.lengthSync(), greaterThan(4000));
    }
  });

  test('sound lengths and hits match the celebrations', () {
    for (final tier in CelebrationTier.values) {
      final spec = timings[tier.name] as Map<String, dynamic>;
      final config = tier.config;
      expect(
          config.seconds, closeTo((spec['duration'] as num).toDouble(), 1e-6),
          reason: '${tier.name} length');

      final titles = config.effectsOf<TitleSlamEffect>().toList();
      if (titles.isNotEmpty) {
        final title = titles.first;
        final impact = title.start * config.seconds + title.impactDelay;
        expect(impact, closeTo((spec['impact'] as num).toDouble(), 0.02),
            reason: '${tier.name} title lands on the hit');
      }

      final bursts = (spec['fireworks'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const <double>[];
      final fireworks = config.effectsOf<FireworksEffect>().toList();
      expect(fireworks.isEmpty, bursts.isEmpty, reason: tier.name);
      if (fireworks.isEmpty) continue;
      final f = fireworks.single;
      expect(f.shells, bursts.length);
      final start = f.start * config.seconds;
      final span = (f.end - f.start) * config.seconds;
      final gap =
          (span - fireworkRiseSeconds - fireworkSparkSeconds) / (f.shells - 1);
      for (var i = 0; i < f.shells; i++) {
        expect(start + i * gap + fireworkRiseSeconds, closeTo(bursts[i], 0.02),
            reason: '${tier.name} firework $i');
      }
    }
  });

  test('custom tiers carry their own config', () {
    const config = CelebrationConfig(
      duration: Duration(seconds: 2),
      effects: <CelebrationEffect>[CoinsEffect(count: 5)],
    );
    const tier = CelebrationTier.custom(config, name: 'coins');
    expect(tier.isCustom, isTrue);
    expect(tier.level, -1);
    expect(tier.name, 'coins');
    expect(identical(tier.config, config), isTrue);
    expect(tier, isNot(CelebrationTier.great));
  });
}
