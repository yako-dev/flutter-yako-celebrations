import 'package:flutter/widgets.dart';

/// Your app's name and icon, shown in the celebration.
///
/// The icon pops up in [BrandPopEffect]; the name shows in a small badge when
/// [CelebrationConfig.showBrandBadge] is on. Pass a brand per call, or once
/// for the whole app with `YakoCelebration.configure(brand: ...)`.
///
/// Give either a widget [icon] or an [image], not both:
///
/// ```dart
/// const CelebrationBrand(name: 'MyApp', image: AssetImage('assets/logo.png'))
/// CelebrationBrand(name: 'MyApp', icon: MyLogo())
/// ```
///
/// Tip: a square icon with a transparent background looks best.
@immutable
class CelebrationBrand {
  /// Creates a brand.
  const CelebrationBrand({this.name, this.icon, this.image, this.color})
      : assert(icon == null || image == null, 'Pass icon or image, not both.');

  /// Your app's name, shown in the brand badge.
  final String? name;

  /// Your icon as a widget. It is drawn many times, at many sizes.
  ///
  /// A widget with its own size (an `Icon`, a sized SVG) is scaled to fit;
  /// a widget that fills its space gets a square to fill.
  final Widget? icon;

  /// Your icon as an image.
  final ImageProvider? image;

  /// Overrides the glow colour behind your icon. Defaults to the
  /// celebration's colour.
  final Color? color;

  /// Whether an icon or image was given.
  bool get hasMark => icon != null || image != null;

  @override
  bool operator ==(Object other) =>
      other is CelebrationBrand &&
      other.name == name &&
      other.icon == icon &&
      other.image == image &&
      other.color == color;

  @override
  int get hashCode => Object.hash(name, icon, image, color);

  @override
  String toString() => 'CelebrationBrand(${name ?? 'unnamed'})';
}
