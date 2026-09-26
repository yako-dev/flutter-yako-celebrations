import 'package:flutter_test/flutter_test.dart';
import 'package:yako_celebrations/src/engine/run.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

import 'helpers/harness.dart';

void main() {
  group('resolveSound', () {
    final epic = CelebrationTier.epic;
    const mine = CelebrationSound.asset('assets/win.mp3');
    const perCall = CelebrationSound.url('https://example.com/a.mp3');

    test('uses the tier sound by default', () {
      expect(resolveSound(tier: epic, config: epic.config),
          const CelebrationSound.builtIn(CelebrationTier.epic));
    });

    test('an app-wide tier sound beats the built-in one', () {
      expect(
        resolveSound(
          tier: epic,
          config: epic.config,
          tierSounds: const <CelebrationTier, CelebrationSound>{
            CelebrationTier.epic: mine,
          },
        ),
        mine,
      );
    });

    test('a per-call sound beats everything', () {
      expect(
        resolveSound(
          tier: epic,
          config: epic.config,
          override: perCall,
          tierSounds: const <CelebrationTier, CelebrationSound>{
            CelebrationTier.epic: mine,
          },
        ),
        perCall,
      );
    });

    test('app-wide sounds only apply to their own tier', () {
      expect(
        resolveSound(
          tier: CelebrationTier.nice,
          config: CelebrationTier.nice.config,
          tierSounds: const <CelebrationTier, CelebrationSound>{
            CelebrationTier.epic: mine,
          },
        ),
        const CelebrationSound.builtIn(CelebrationTier.nice),
      );
    });

    test('none() and mute give silence', () {
      expect(
        resolveSound(
          tier: epic,
          config: epic.config,
          override: const CelebrationSound.none(),
        ),
        isNull,
      );
      expect(
        resolveSound(
            tier: epic, config: epic.config, override: perCall, muted: true),
        isNull,
      );
      expect(
        resolveSound(
          tier: const CelebrationTier.custom(CelebrationConfig()),
          config: const CelebrationConfig(),
        ),
        isNull,
        reason: 'custom configs are silent unless they pick a sound',
      );
    });
  });

  group('CelebrationSound', () {
    test('asset keys', () {
      expect(const AssetCelebrationSound('a/b.mp3').assetKey, 'a/b.mp3');
      expect(const AssetCelebrationSound('a/b.mp3', package: 'p').assetKey,
          'packages/p/a/b.mp3');
    });

    test('built-in sound of a custom tier is silent', () {
      const custom = CelebrationTier.custom(CelebrationConfig());
      expect(const CelebrationSound.builtIn(custom).isSilent, isTrue);
      expect(const CelebrationSound.builtIn(CelebrationTier.epic).isSilent,
          isFalse);
    });

    test('ids are distinct per source', () {
      final ids = <String>{
        const CelebrationSound.builtIn(CelebrationTier.epic).id,
        const CelebrationSound.asset('x.mp3').id,
        const CelebrationSound.file('x.mp3').id,
        const CelebrationSound.url('x.mp3').id,
        const CelebrationSound.none().id,
      };
      expect(ids, hasLength(5));
    });
  });

  group('show() plays the resolved sound', () {
    setUp(resetCelebrations);
    tearDown(resetCelebrations);

    testWidgets('through onPlaySound, with overrides in order', (tester) async {
      final played = <CelebrationSound>[];
      YakoCelebration.configure(
        preloadSounds: false,
        onPlaySound: played.add,
        sounds: const <CelebrationTier, CelebrationSound>{
          CelebrationTier.nice: CelebrationSound.asset('assets/nice.mp3'),
        },
      );
      final context = await pumpHost(tester);

      YakoCelebration.show(context, tier: CelebrationTier.epic);
      await tester.pump();
      YakoCelebration.show(context, tier: CelebrationTier.nice);
      await tester.pump();
      YakoCelebration.show(context,
          tier: CelebrationTier.nice,
          sound: const CelebrationSound.file('/tmp/x.mp3'));
      await tester.pump();
      YakoCelebration.show(context,
          tier: CelebrationTier.great, sound: const CelebrationSound.none());
      await tester.pump();

      expect(played, <CelebrationSound>[
        const CelebrationSound.builtIn(CelebrationTier.epic),
        const CelebrationSound.asset('assets/nice.mp3'),
        const CelebrationSound.file('/tmp/x.mp3'),
      ]);
      YakoCelebration.cancelAll();
      await tester.pumpAndSettle();
    });

    testWidgets('nothing plays while muted', (tester) async {
      final played = <CelebrationSound>[];
      YakoCelebration.configure(
          preloadSounds: false, onPlaySound: played.add, muted: true);
      final context = await pumpHost(tester);
      YakoCelebration.show(context, tier: CelebrationTier.legendary);
      await tester.pump();
      expect(played, isEmpty);
      YakoCelebration.muted = false;
      expect(YakoCelebration.muted, isFalse);
      YakoCelebration.show(context, tier: CelebrationTier.legendary);
      await tester.pump();
      expect(played, hasLength(1));
      YakoCelebration.cancelAll();
      await tester.pumpAndSettle();
    });
  });
}
