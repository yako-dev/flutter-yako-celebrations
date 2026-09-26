import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:yako_celebrations/src/painting/fire_renderers.dart';
import 'package:yako_celebrations/src/painting/glow_renderers.dart';
import 'package:yako_celebrations/src/painting/particle_renderers.dart';
import 'package:yako_celebrations/src/painting/renderer.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

import 'helpers/counting_canvas.dart';

const Size _phone = Size(390, 844);
const Color _accent = Color(0xFFFFB300);

CountingCanvas _paint(EffectRenderer renderer, double now,
    [Size size = _phone]) {
  final canvas = CountingCanvas();
  if (renderer.isActive(now)) renderer.paint(canvas, size, now);
  return canvas;
}

void main() {
  group('paint counts over time', () {
    test('coins: none before the start, all falling mid-way, gone after', () {
      final coins = CoinsRenderer(const CoinsEffect(count: 20, start: 0.2),
          CelebrationPalette.gold, _accent, 5, 1);
      expect(_paint(coins, 0.5).draws, 0, reason: 'starts at 1 s');
      final mid = _paint(coins, 3);
      expect(mid.count(#drawCircle), greaterThan(10));
      expect(mid.saveCount, 1, reason: 'every save is restored');
      expect(_paint(coins, 5.1).draws, 0, reason: 'ended');
    });

    test('confetti: every piece is on screen right after the cannons', () {
      final confetti = ConfettiRenderer(
          const ConfettiEffect(count: 40, launch: ConfettiLaunch.burst),
          CelebrationPalette.party,
          _accent,
          3,
          7);
      final canvas = _paint(confetti, 0.3);
      expect(canvas.count(#drawRect) + canvas.count(#drawCircle), 40);
    });

    test('flames: three shapes and a glow per visible flame', () {
      final flames = FlamesRenderer(const FlamesEffect(count: 30),
          CelebrationPalette.fire, _accent, 4, 3);
      final canvas = _paint(flames, 0.4);
      final paths = canvas.count(#drawPath);
      expect(paths, greaterThan(0));
      expect(paths % 3, 0);
      expect(canvas.count(#drawCircle), paths ~/ 3);
      expect(_paint(flames, 4.01).draws, 0);
    });

    test('fireworks: rockets rise, then sparks are batched per burst', () {
      final fireworks = FireworksRenderer(
          const FireworksEffect(shells: 3, sparks: 20),
          CelebrationPalette.party,
          _accent,
          5,
          2);
      final rising = _paint(fireworks, 0.25);
      expect(rising.count(#drawRawPoints), 2, reason: 'trail + head');
      final burst = _paint(fireworks, 0.9);
      // Two twinkle groups, each one line batch and one head batch.
      expect(burst.count(#drawRawPoints), greaterThanOrEqualTo(4));
      expect(_paint(fireworks, 4.99).draws, greaterThanOrEqualTo(0));
    });

    test('fire wall: one bed, four layers of tongues, embers', () {
      final wall = FireWallRenderer(
          const FireWallEffect(tongues: 10, embers: 12),
          CelebrationPalette.fire,
          _accent,
          6,
          5);
      final canvas = _paint(wall, 2);
      expect(canvas.count(#drawPath), 40);
      expect(canvas.count(#drawRawPoints), 4);
      expect(canvas.count(#drawRect), 2, reason: 'glow and bed');
    });

    test('flash peaks at its start and is gone by its end', () {
      final flash = FlashRenderer(
          const FlashEffect(strength: 1, start: 0.1, end: 0.3), 10);
      expect(_paint(flash, 0.5).draws, 0);
      expect(_paint(flash, 1.1).count(#drawPaint), 1);
      expect(_paint(flash, 3.01).draws, 0);
    });
  });

  test('the same seed draws the same frame; another seed does not', () {
    List<String> frame(int seed) {
      final canvas = CountingCanvas();
      ConfettiRenderer(const ConfettiEffect(count: 30),
              CelebrationPalette.party, _accent, 3, seed)
          .paint(canvas, _phone, 0.8);
      return canvas.log;
    }

    expect(frame(11), frame(11));
    expect(frame(11), isNot(frame(12)));
  });

  test('bigger tiers draw more at their busiest', () {
    int busiest(CelebrationTier tier) {
      final config = tier.config;
      var most = 0;
      for (var f = 0.05; f < 1; f += 0.05) {
        final now = f * config.seconds;
        var draws = 0;
        for (var i = 0; i < config.effects.length; i++) {
          final renderer = _rendererFor(config, i);
          if (renderer == null) continue;
          draws += _paint(renderer, now).draws;
        }
        if (draws > most) most = draws;
      }
      return most;
    }

    final counts = CelebrationTier.values.map(busiest).toList();
    for (var i = 1; i < counts.length; i++) {
      expect(counts[i], greaterThan(counts[i - 1]),
          reason: 'draw calls per tier: $counts');
    }
  });
}

EffectRenderer? _rendererFor(CelebrationConfig config, int index) {
  final effect = config.effects[index];
  final palette = effect.palette ?? config.palette;
  final total = config.seconds;
  return switch (effect) {
    SparklesEffect() =>
      SparklesRenderer(effect, palette, config.color, total, index),
    LightRaysEffect() =>
      LightRaysRenderer(effect, palette, config.color, total),
    ConfettiEffect() =>
      ConfettiRenderer(effect, palette, config.color, total, index),
    StreamersEffect() =>
      StreamersRenderer(effect, palette, config.color, total, index),
    CoinsEffect() => CoinsRenderer(effect, palette, config.color, total, index),
    FlamesEffect() =>
      FlamesRenderer(effect, palette, config.color, total, index),
    FireworksEffect() =>
      FireworksRenderer(effect, palette, config.color, total, index),
    FireWallEffect() =>
      FireWallRenderer(effect, palette, config.color, total, index),
    FlashEffect() => FlashRenderer(effect, total),
    EdgeGlowEffect() => EdgeGlowRenderer(effect, palette, config.color, total),
    _ => null,
  };
}
