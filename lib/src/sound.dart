import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tier.dart';

/// Plays a sound yourself instead of letting the package do it.
///
/// Pass one to `YakoCelebration.configure(onPlaySound: ...)` if your app has
/// its own audio stack. Built-in sounds are package assets; their asset key is
/// [BuiltInCelebrationSound.assetKey].
typedef CelebrationSoundHandler = FutureOr<void> Function(
    CelebrationSound sound);

/// The sound a celebration plays.
///
/// ```dart
/// CelebrationSound.builtIn(CelebrationTier.epic) // one of ours
/// CelebrationSound.asset('assets/sounds/win.mp3') // from your app
/// CelebrationSound.file('/path/on/device.mp3')
/// CelebrationSound.url('https://example.com/win.mp3')
/// CelebrationSound.none()
/// ```
///
/// Every built-in sound is synthesised by the package's own script, so you
/// may ship it in any app.
@immutable
sealed class CelebrationSound {
  const CelebrationSound._(this.volume)
      : assert(volume >= 0 && volume <= 1, 'volume goes from 0 to 1');

  /// The built-in sound of a ready-made [tier].
  ///
  /// Its length matches that tier's length. For a custom tier this is silent.
  const factory CelebrationSound.builtIn(
    CelebrationTier tier, {
    double volume,
  }) = BuiltInCelebrationSound;

  /// An asset bundled with your app, e.g. `'assets/sounds/win.mp3'`.
  ///
  /// Set [package] to play an asset from another package.
  const factory CelebrationSound.asset(
    String path, {
    String? package,
    double volume,
  }) = AssetCelebrationSound;

  /// A file on the device.
  const factory CelebrationSound.file(String path, {double volume}) =
      FileCelebrationSound;

  /// A sound from the network.
  const factory CelebrationSound.url(String url, {double volume}) =
      UrlCelebrationSound;

  /// No sound.
  const factory CelebrationSound.none() = NoCelebrationSound;

  /// Playback volume from 0 to 1.
  final double volume;

  /// A stable id, used to keep one prepared player per sound.
  String get id;

  /// Whether this plays anything at all.
  bool get isSilent => false;
}

/// A sound that ships with the package. See [CelebrationSound.builtIn].
final class BuiltInCelebrationSound extends CelebrationSound {
  /// The built-in sound of [tier].
  const BuiltInCelebrationSound(this.tier, {double volume = 1})
      : super._(volume);

  /// The tier whose sound this is.
  final CelebrationTier tier;

  /// The Flutter asset key of the sound file.
  String get assetKey =>
      'packages/yako_celebrations/assets/sounds/${tier.name}.mp3';

  @override
  String get id => 'builtin:${tier.name}';

  @override
  bool get isSilent => tier.isCustom;

  @override
  bool operator ==(Object other) =>
      other is BuiltInCelebrationSound &&
      other.tier == tier &&
      other.volume == volume;

  @override
  int get hashCode => Object.hash(tier, volume);

  @override
  String toString() => 'CelebrationSound.builtIn(${tier.name})';
}

/// A sound from your app's assets. See [CelebrationSound.asset].
final class AssetCelebrationSound extends CelebrationSound {
  /// An asset sound.
  const AssetCelebrationSound(this.path, {this.package, double volume = 1})
      : super._(volume);

  /// Path of the asset as listed in `pubspec.yaml`.
  final String path;

  /// The package that owns the asset, or `null` for your app.
  final String? package;

  /// The Flutter asset key of the sound file.
  String get assetKey => package == null ? path : 'packages/$package/$path';

  @override
  String get id => 'asset:$assetKey';

  @override
  bool operator ==(Object other) =>
      other is AssetCelebrationSound &&
      other.assetKey == assetKey &&
      other.volume == volume;

  @override
  int get hashCode => Object.hash(assetKey, volume);

  @override
  String toString() => 'CelebrationSound.asset($assetKey)';
}

/// A sound file on the device. See [CelebrationSound.file].
final class FileCelebrationSound extends CelebrationSound {
  /// A device file sound.
  const FileCelebrationSound(this.path, {double volume = 1}) : super._(volume);

  /// Absolute path of the file.
  final String path;

  @override
  String get id => 'file:$path';

  @override
  bool operator ==(Object other) =>
      other is FileCelebrationSound &&
      other.path == path &&
      other.volume == volume;

  @override
  int get hashCode => Object.hash(path, volume);

  @override
  String toString() => 'CelebrationSound.file($path)';
}

/// A sound from the network. See [CelebrationSound.url].
final class UrlCelebrationSound extends CelebrationSound {
  /// A network sound.
  const UrlCelebrationSound(this.url, {double volume = 1}) : super._(volume);

  /// Where to fetch the sound.
  final String url;

  @override
  String get id => 'url:$url';

  @override
  bool operator ==(Object other) =>
      other is UrlCelebrationSound &&
      other.url == url &&
      other.volume == volume;

  @override
  int get hashCode => Object.hash(url, volume);

  @override
  String toString() => 'CelebrationSound.url($url)';
}

/// Silence. See [CelebrationSound.none].
final class NoCelebrationSound extends CelebrationSound {
  /// No sound.
  const NoCelebrationSound() : super._(0);

  @override
  String get id => 'none';

  @override
  bool get isSilent => true;

  @override
  bool operator ==(Object other) => other is NoCelebrationSound;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'CelebrationSound.none()';
}
