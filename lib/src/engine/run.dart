// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../brand.dart';
import '../config.dart';
import '../sound.dart';
import '../tier.dart';
import 'audio.dart';
import 'shake.dart';

/// App-wide settings from `YakoCelebration.configure`.
abstract final class CelebrationGlobals {
  static CelebrationBrand? brand;
  static bool muted = false;
  static bool haptics = true;
  static Map<CelebrationTier, CelebrationSound> sounds =
      const <CelebrationTier, CelebrationSound>{};
  static CelebrationSoundHandler? onPlaySound;
  static bool manageAudioSession = true;

  static CelebrationAudioBackend? _backend;

  static CelebrationAudioBackend get backend =>
      _backend ??= AudioplayersBackend.platformDefault(
          manageAudioSession: manageAudioSession);

  static set backend(CelebrationAudioBackend? value) => _backend = value;

  /// Shake of celebrations shown with `YakoCelebration.show`.
  static final ShakeNotifier shake = ShakeNotifier();
}

/// Picks the sound to play, or `null` for silence.
///
/// Order: the per-call [override], then the app-wide sound for [tier], then
/// the config's own sound. Nothing plays while [muted].
CelebrationSound? resolveSound({
  required CelebrationTier tier,
  required CelebrationConfig config,
  CelebrationSound? override,
  Map<CelebrationTier, CelebrationSound> tierSounds =
      const <CelebrationTier, CelebrationSound>{},
  bool muted = false,
}) {
  if (muted) return null;
  final sound = override ?? tierSounds[tier] ?? config.sound;
  if (sound == null || sound.isSilent) return null;
  return sound;
}

/// One celebration from start to finish, whoever hosts it.
class CelebrationRun {
  CelebrationRun({
    required this.tier,
    required this.brand,
    required String? title,
    required String? subtitle,
    required this.soundOverride,
    required this.onComplete,
    required this.seed,
    required this.shake,
  })  : title = ValueNotifier<String?>(title ?? tier.config.title),
        subtitle = ValueNotifier<String?>(subtitle ?? tier.config.subtitle);

  final CelebrationTier tier;
  final CelebrationBrand? brand;
  final ValueNotifier<String?> title;
  final ValueNotifier<String?> subtitle;
  final CelebrationSound? soundOverride;
  final VoidCallback? onComplete;
  final int seed;
  final ShakeNotifier shake;

  /// Set by the host: takes the celebration off the screen.
  VoidCallback? detach;

  /// Set by the clock owner: stops the clock so no frame runs after the end.
  VoidCallback? halt;

  final Completer<void> _done = Completer<void>();
  SoundPlayback? _playback;

  bool get isActive => !_done.isCompleted;

  Future<void> get done => _done.future;

  /// Starts the sound for [config] (the reduced-motion one, if in use).
  void startSound(CelebrationConfig config) {
    final sound = resolveSound(
      tier: tier,
      config: config,
      override: soundOverride,
      tierSounds: CelebrationGlobals.sounds,
      muted: CelebrationGlobals.muted,
    );
    if (sound == null) return;
    final handler = CelebrationGlobals.onPlaySound;
    if (handler != null) {
      try {
        final result = handler(sound);
        if (result is Future<void>) {
          unawaited(result.catchError((Object error) => _log(error)));
        }
      } catch (error) {
        _log(error);
      }
      return;
    }
    unawaited(CelebrationGlobals.backend.play(sound).then((playback) {
      if (isActive) {
        _playback = playback;
      } else {
        playback?.stop();
      }
    }).catchError((Object error) => _log(error)));
  }

  void stopSound() {
    _playback?.stop();
    _playback = null;
  }

  /// The celebration ran to its end.
  void finish() {
    if (!isActive) return;
    _close();
    onComplete?.call();
  }

  /// The celebration was stopped early.
  void cancel() {
    if (!isActive) return;
    stopSound();
    _close();
  }

  void _close() {
    halt?.call();
    halt = null;
    shake.reset();
    _done.complete();
    final remove = detach;
    detach = null;
    remove?.call();
  }

  static void _log(Object error) {
    if (kDebugMode) debugPrint('yako_celebrations: sound failed: $error');
  }
}

/// Controls a celebration that is on the screen.
///
/// Returned by `YakoCelebration.show` and `CelebrationController.celebrate`.
class CelebrationHandle {
  /// Wraps a running celebration. Made by the package, not by apps.
  @internal
  CelebrationHandle(this._run);

  final CelebrationRun _run;

  /// The tier being shown.
  CelebrationTier get tier => _run.tier;

  /// Whether the celebration is still on the screen.
  bool get isActive => _run.isActive;

  /// Completes when the celebration ends, whether it finished or was
  /// cancelled.
  Future<void> get done => _run.done;

  /// The current title.
  String? get title => _run.title.value;

  /// The current subtitle.
  String? get subtitle => _run.subtitle.value;

  /// Stops the celebration and its sound right away.
  ///
  /// `onComplete` is not called. Does nothing if it already ended.
  void cancel() => _run.cancel();

  /// Changes the title while the celebration runs.
  void updateTitle(String? title) => _run.title.value = title;

  /// Changes the subtitle while the celebration runs, e.g. to count up a
  /// score.
  void updateSubtitle(String? subtitle) => _run.subtitle.value = subtitle;
}
