import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'brand.dart';
import 'effects.dart';
import 'engine/live.dart';
import 'engine/lottie_layer.dart';
import 'engine/run.dart';
import 'sound.dart';
import 'tier.dart';

/// Shows celebrations and holds the app-wide settings.
///
/// The one line:
///
/// ```dart
/// YakoCelebration.show(context, tier: CelebrationTier.epic);
/// ```
abstract final class YakoCelebration {
  static final List<CelebrationRun> _active = <CelebrationRun>[];
  static final math.Random _random = math.Random();

  /// Sets app-wide defaults. Every call replaces all earlier settings.
  ///
  /// * [brand]: your name and icon, used when a call passes no brand.
  /// * [muted]: no sound at all.
  /// * [haptics]: whether to play haptic taps.
  /// * [sounds]: your own sound for any tier, e.g.
  ///   `{CelebrationTier.epic: CelebrationSound.asset('assets/epic.mp3')}`.
  /// * [onPlaySound]: play sounds yourself (your own audio stack). When set,
  ///   the package never plays audio itself.
  /// * [manageAudioSession]: let the package set an audio session that mixes
  ///   with the user's music and respects the silent switch on iOS. Turn off
  ///   if your app configures `audioplayers`' audio context itself.
  /// * [preloadSounds]: load the built-in sounds now, so the first
  ///   celebration does not pay for it (see [preload]).
  static void configure({
    CelebrationBrand? brand,
    bool muted = false,
    bool haptics = true,
    Map<CelebrationTier, CelebrationSound> sounds =
        const <CelebrationTier, CelebrationSound>{},
    CelebrationSoundHandler? onPlaySound,
    bool manageAudioSession = true,
    bool preloadSounds = true,
  }) {
    final sessionChanged =
        manageAudioSession != CelebrationGlobals.manageAudioSession;
    CelebrationGlobals.brand = brand;
    CelebrationGlobals.muted = muted;
    CelebrationGlobals.haptics = haptics;
    CelebrationGlobals.sounds =
        Map<CelebrationTier, CelebrationSound>.unmodifiable(sounds);
    CelebrationGlobals.onPlaySound = onPlaySound;
    CelebrationGlobals.manageAudioSession = manageAudioSession;
    if (sessionChanged) CelebrationGlobals.backend = null;
    if (preloadSounds && !muted && onPlaySound == null) unawaited(preload());
  }

  /// The app-wide brand set with [configure].
  static CelebrationBrand? get brand => CelebrationGlobals.brand;

  /// Whether sound is off app-wide.
  static bool get muted => CelebrationGlobals.muted;

  /// Turns sound off (or back on) app-wide. Muting stops sounds that are
  /// playing.
  static set muted(bool value) {
    CelebrationGlobals.muted = value;
    if (value) {
      for (final run in _active) {
        run.stopSound();
      }
      unawaited(CelebrationGlobals.backend.stopAll());
    }
  }

  /// Whether haptic taps are on app-wide.
  static bool get hapticsEnabled => CelebrationGlobals.haptics;

  /// Turns haptic taps on or off app-wide.
  static set hapticsEnabled(bool value) => CelebrationGlobals.haptics = value;

  /// Loads the sounds and Lottie files of [tiers] (the code-drawn tiers by
  /// default, plus any app-wide [configure] sounds for them) so they start
  /// instantly.
  ///
  /// Using the Lottie ladder? Call
  /// `YakoCelebration.preload(CelebrationTier.lottieValues)` once at start-up.
  ///
  /// Safe to call more than once; loading happens only the first time.
  static Future<void> preload([
    Iterable<CelebrationTier> tiers = CelebrationTier.values,
  ]) async {
    final files = <String>{
      for (final tier in tiers)
        for (final effect in tier.config.effectsOf<LottieEffect>())
          effect.assetKey,
    };
    final lottie = Future.wait(files.map(CelebrationLottieCache.load));
    final muted = CelebrationGlobals.muted;
    final ownAudio = CelebrationGlobals.onPlaySound != null;
    if (!muted && !ownAudio) {
      final backend = CelebrationGlobals.backend;
      // One at a time: native players are happier loading in turn.
      for (final tier in tiers) {
        final sound = CelebrationGlobals.sounds[tier] ?? tier.config.sound;
        if (sound == null || sound.isSilent) continue;
        try {
          await backend.prepare(sound);
        } catch (_) {
          // A sound that fails to load is tried again when it is played.
        }
      }
    }
    await lottie;
  }

  /// The screen shake of celebrations shown with [show].
  ///
  /// `CelebrationShaker` listens to this by default; use it to shake your own
  /// widgets in time with the celebration.
  static ValueListenable<Offset> get shake => CelebrationGlobals.shake;

  /// Whether a celebration shown with [show] is on the screen.
  static bool get isCelebrating => _active.isNotEmpty;

  /// Shows a full-screen celebration over everything, in the root [Overlay].
  ///
  /// * [tier]: how big (see [CelebrationTier]), or your own with
  ///   [CelebrationTier.custom].
  /// * [title], [subtitle]: override the tier's text. Pass `''` to hide the
  ///   title.
  /// * [brand]: overrides the app-wide brand from [configure].
  /// * [sound]: overrides the tier's sound for this call.
  /// * [onComplete]: called when the celebration ends by itself (not when it
  ///   is cancelled).
  /// * [exclusive]: cancel any celebration already on the screen first.
  /// * [seed]: fixes the random layout; `null` uses the config's seed, or a
  ///   new layout every time.
  ///
  /// Never blocks the UI: the overlay ignores touches. Returns a handle to
  /// cancel it or change its text while it runs.
  static CelebrationHandle show(
    BuildContext context, {
    CelebrationTier tier = CelebrationTier.great,
    String? title,
    String? subtitle,
    CelebrationBrand? brand,
    CelebrationSound? sound,
    VoidCallback? onComplete,
    bool exclusive = true,
    int? seed,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('YakoCelebration.show() found no Overlay.'),
        ErrorDescription(
          'Call it with a context below MaterialApp, CupertinoApp or '
          'WidgetsApp, or use CelebrationOverlay with a CelebrationController.',
        ),
      ]);
    }
    if (exclusive) cancelAll();
    final run = CelebrationRun(
      tier: tier,
      brand: brand ?? CelebrationGlobals.brand,
      title: title,
      subtitle: subtitle,
      soundOverride: sound,
      onComplete: onComplete,
      seed: seed ?? tier.config.seed ?? _random.nextInt(1 << 30),
      shake: CelebrationGlobals.shake,
    );
    final entry = OverlayEntry(
      builder: (context) => LiveCelebration(key: ObjectKey(run), run: run),
    );
    _active.add(run);
    run.detach = () {
      _active.remove(run);
      entry
        ..remove()
        ..dispose();
    };
    overlay.insert(entry);
    return CelebrationHandle(run);
  }

  /// Stops every celebration shown with [show].
  static void cancelAll() {
    for (final run in List<CelebrationRun>.of(_active)) {
      run.cancel();
    }
  }
}
