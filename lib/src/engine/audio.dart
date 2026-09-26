// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../sound.dart';
import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';

/// A sound that is playing and can be stopped.
abstract class SoundPlayback {
  void stop();
}

/// Plays celebration sounds. Swappable so tests never touch a real player.
abstract class CelebrationAudioBackend {
  /// Gets [sound] ready so the first play starts without a delay.
  Future<void> prepare(CelebrationSound sound);

  /// Plays [sound] from the start; returns `null` if it could not play.
  Future<SoundPlayback?> play(CelebrationSound sound);

  /// Stops everything that is playing.
  Future<void> stopAll();
}

/// Does nothing. Used inside `flutter test` and after errors.
class SilentAudioBackend implements CelebrationAudioBackend {
  const SilentAudioBackend();

  @override
  Future<void> prepare(CelebrationSound sound) async {}

  @override
  Future<SoundPlayback?> play(CelebrationSound sound) async => null;

  @override
  Future<void> stopAll() async {}
}

/// The default backend: one prepared `audioplayers` player per sound.
///
/// Built-in sounds are short, so each keeps its own player with the file
/// already loaded. Playing again just rewinds and starts.
class AudioplayersBackend implements CelebrationAudioBackend {
  AudioplayersBackend({required this.manageAudioSession});

  /// Whether to set a mixing, silent-switch-friendly audio session.
  final bool manageAudioSession;

  final Map<String, Future<AudioPlayer?>> _players =
      <String, Future<AudioPlayer?>>{};
  Future<void>? _session;

  /// The backend to use by default on this platform.
  static CelebrationAudioBackend platformDefault({
    required bool manageAudioSession,
  }) {
    if (isFlutterTest) return const SilentAudioBackend();
    return AudioplayersBackend(manageAudioSession: manageAudioSession);
  }

  Future<void> _ensureSession() => _session ??= _setSession();

  Future<void> _setSession() async {
    if (!manageAudioSession) return;
    // Celebration sounds are effects: mix with the user's music, respect the
    // silent switch on iOS, and never take audio focus on Android.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await AudioPlayer.global.setAudioContext(AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ));
    }
  }

  Future<AudioPlayer?> _player(CelebrationSound sound) =>
      _players.putIfAbsent(sound.id, () => _create(sound));

  Future<AudioPlayer?> _create(CelebrationSound sound) async {
    try {
      await _ensureSession();
      final player =
          AudioPlayer(playerId: 'yako_celebrations_${_players.length}')
            ..audioCache = AudioCache(prefix: '');
      await player.setReleaseMode(ReleaseMode.stop);
      if (manageAudioSession &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        await player.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.game,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ));
      }
      final source = switch (sound) {
        BuiltInCelebrationSound() => AssetSource(sound.assetKey),
        AssetCelebrationSound() => AssetSource(sound.assetKey),
        FileCelebrationSound() => DeviceFileSource(sound.path),
        UrlCelebrationSound() => UrlSource(sound.url),
        NoCelebrationSound() => null,
      };
      if (source == null) return null;
      await player.setSource(source);
      return player;
    } catch (error) {
      _players.remove(sound.id)?.ignore();
      _log('could not load $sound: $error');
      return null;
    }
  }

  @override
  Future<void> prepare(CelebrationSound sound) async {
    if (sound.isSilent) return;
    await _player(sound);
  }

  @override
  Future<SoundPlayback?> play(CelebrationSound sound) async {
    if (sound.isSilent) return null;
    final player = await _player(sound);
    if (player == null) return null;
    try {
      await player.stop();
      await player.setVolume(sound.volume);
      await player.resume();
      return _Playback(player);
    } catch (error) {
      _log('could not play $sound: $error');
      return null;
    }
  }

  @override
  Future<void> stopAll() async {
    for (final future in _players.values) {
      final player = await future;
      try {
        await player?.stop();
      } catch (_) {
        // Nothing to do: the player is gone or never started.
      }
    }
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('yako_celebrations: $message');
  }
}

class _Playback implements SoundPlayback {
  _Playback(this._player);

  final AudioPlayer _player;

  @override
  void stop() {
    unawaited(_player.stop().catchError((Object _) {}));
  }
}
