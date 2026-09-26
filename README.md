# Yako Celebrations

Full-screen celebrations for Flutter in one line: flames, spinning coins,
confetti, fireworks, **your own logo popping up everywhere**, a slamming title,
flash, shake, sound and haptics. Pick a ready-made tier or build your own.

<p align="center">
  <img src="https://raw.githubusercontent.com/yako-dev/flutter-yako-celebrations/main/screenshots/legendary.webp" width="300" alt="The legendary tier: rainbow flames, a wall of fire, fireworks and a storm of brand icons">
</p>

Everything is drawn in code (no Lottie files), runs on one clock, and never
blocks touches. Every built-in sound is synthesised by the package's own
script, so you can ship it in any app.

## Installing

```yaml
dependencies:
  yako_celebrations: ^0.1.0
```

## Quick start

```dart
import 'package:yako_celebrations/yako_celebrations.dart';

YakoCelebration.show(context, tier: CelebrationTier.epic);
```

That's it: the celebration covers the whole screen, plays its sound and
haptics, and cleans up after itself.

Change the text, or keep a handle to change it while it runs:

```dart
final handle = YakoCelebration.show(
  context,
  tier: CelebrationTier.legendary,
  title: 'Level 10!',
  subtitle: 'NEW RECORD',
  onComplete: () => print('done'),
);

handle.updateSubtitle('+2,500 XP');
handle.cancel(); // stop early
```

## Tiers

<p align="center">
  <img src="https://raw.githubusercontent.com/yako-dev/flutter-yako-celebrations/main/screenshots/tiers.webp" alt="The five tiers, from subtle to legendary">
</p>

| Tier | Length | What happens |
|---|---|---|
| `subtle` | 1.2 s | A quick sparkle and a small chime. For "saved", "done". |
| `nice` | 2.2 s | Title pop, a burst of confetti, sparkles. |
| `great` | 3.4 s | Title slam, light rays, confetti cannons, streamers, a few brand pops. |
| `epic` | 5 s | Flames, coins, fireworks, a storm of brand pops, flash and shake. |
| `legendary` | 7.5 s | Rainbow flames, a wall of fire, giant brand pops, fireworks, big flash and shake. |

Each tier is longer and bigger than the one below it, and each has its own
sound, as long as the celebration itself.

## Your brand

Give the package your name and icon once. The icon pops up in the brand-pop
effect, alongside the flames and coins; the name shows in a small badge on
the bigger tiers.

```dart
void main() {
  YakoCelebration.configure(
    brand: CelebrationBrand(
      name: 'MyApp',
      image: const AssetImage('assets/logo.png'), // or icon: MyLogo()
    ),
  );
  runApp(const MyApp());
}
```

Pass `brand:` to `show` to use another one for a single call. Without a brand,
a neutral star pops up instead. A square icon with a transparent background
looks best.

## Build your own

A tier is just a `CelebrationConfig`. Start from a preset...

```dart
final streak = CelebrationTier.custom(
  CelebrationTier.epic.config.copyWith(
    title: 'STREAK!',
    color: Colors.pinkAccent,
    duration: const Duration(seconds: 4),
  ),
);
YakoCelebration.show(context, tier: streak);
```

...or from scratch:

```dart
final levelUp = CelebrationTier.custom(
  CelebrationConfig(
    duration: const Duration(seconds: 4),
    title: 'Level up!',
    subtitle: '+1 skill point',
    color: Colors.teal,
    backgroundDim: 0.4,
    effects: const [
      TitleSlamEffect(slamFrom: 2.4),
      LightRaysEffect(),
      ConfettiEffect(count: 150, launch: ConfettiLaunch.cannons),
      CoinsEffect(count: 40, start: 0.1, end: 0.8),
      FireworksEffect(shells: 3, area: CelebrationArea.topBand),
      FlashEffect(strength: 0.5, start: 0.03, end: 0.12),
      ShakeEffect(strength: 10, start: 0.03, end: 0.2),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.epic),
    haptics: const CelebrationHaptics([
      HapticPulse(0.05, CelebrationHapticKind.heavy),
    ]),
  ),
);
```

`start` and `end` are fractions of the whole length, so a tweaked duration
keeps everything in step. Handy helpers: `config.without<ShakeEffect>()`,
`config.withEffects([...])`.

| Effect | What it draws | Main options |
|---|---|---|
| `TitleSlamEffect` | Title slamming in with a bounce, plus the subtitle | `slamFrom`, `fontSize`, `style`, `alignment`, `gradient`, `glow` |
| `FlamesEffect` | Little flames bursting out and drifting | `count`, `size`, `area` (burst, fountain, shower, drift) |
| `CoinsEffect` | Spinning gold coins raining down | `count`, `size`, `area` |
| `ConfettiEffect` | Fluttering paper confetti | `count`, `size`, `launch` (cannons, burst, rain) |
| `StreamersEffect` | Long curly ribbons | `count`, `size`, `launch` |
| `FireworksEffect` | Shells rising and bursting | `shells`, `sparks`, `size`, `area` |
| `SparklesEffect` | Twinkling stars | `count`, `size`, `area` |
| `LightRaysEffect` | Turning beams behind the title | `rays`, `spin`, `opacity` |
| `BrandPopEffect` | Your icon popping up in a staggered storm | `count`, `minSize`, `maxSize`, `glow` |
| `FireWallEffect` | Big animated flames along the bottom | `height`, `tongues`, `embers` |
| `FlashEffect` | A full-screen camera flash | `strength`, `color` |
| `ShakeEffect` | Screen shake | `strength`, `frequency` |
| `EdgeGlowEffect` | A pulsing glow around the edges | `strength`, `pulse` |

Every effect takes a `palette`: `CelebrationPalette.gold`, `.fire`, `.party`,
`.rainbow` (hue-shifting over time), `.accent` (shades of the config's
`color`) or your own list of colours.

### Your own layers

Want your own Lottie or widget in the show? Add it on the same clock:

```dart
CelebrationConfig(
  extraLayers: [
    (context, progress) => MyLottie(progress: progress),
  ],
)
```

`progress` runs from 0 to 1 and follows slow motion and cancelling like every
built-in effect.

## Sound

Every tier plays its own built-in sound. Change it per call, per tier, or turn
it off:

```dart
// Just this once.
YakoCelebration.show(context,
    tier: CelebrationTier.epic,
    sound: const CelebrationSound.asset('assets/sounds/win.mp3'));

// App-wide, per tier, and a global mute.
YakoCelebration.configure(
  sounds: const {
    CelebrationTier.legendary: CelebrationSound.url('https://example.com/win.mp3'),
    CelebrationTier.subtle: CelebrationSound.none(),
  },
);
YakoCelebration.muted = true;
```

Sources: `CelebrationSound.builtIn(tier)`, `.asset(path)`, `.file(path)`,
`.url(url)`, `.none()`.

- Sounds play through [`audioplayers`](https://pub.dev/packages/audioplayers)
  and are preloaded by `configure`, so the first celebration starts instantly.
- By default the package sets an iOS audio session that mixes with the user's
  music and respects the silent switch, and takes no audio focus on Android.
  If your app configures `audioplayers` itself, pass
  `manageAudioSession: false`.
- Have your own audio stack? Pass `onPlaySound` and the package hands you the
  sound instead of playing it. Built-in sounds are package assets:
  `(sound as BuiltInCelebrationSound).assetKey`.

## Haptics

Each tier has a haptic pattern on the celebration's clock (heavy thump on the
title hit, lighter taps on each firework...). It uses Flutter's own
`HapticFeedback`, no plugin. Turn it off with
`YakoCelebration.hapticsEnabled = false`.

## Shake your app

The title always shakes on the hit. To shake your whole app too, wrap it once:

```dart
MaterialApp(
  builder: (context, child) => CelebrationShaker(child: child!),
);
```

Only the paint position moves; layout and touches keep working.

## Inside one part of the screen

`show` uses the root overlay. To keep a celebration inside a widget (and shake
just that widget), use a controller:

```dart
final controller = CelebrationController();

CelebrationOverlay(
  controller: controller,
  child: GameBoard(),
);

controller.celebrate(tier: CelebrationTier.great, subtitle: 'Combo x3');
```

## Previews

`CelebrationPreview` draws any moment of a celebration without playing it:
great for a settings screen, a scrubber, or screenshots.

```dart
CelebrationPreview(
  tier: CelebrationTier.legendary,
  progress: const AlwaysStoppedAnimation(0.3),
)
```

## Accessibility and performance

- When the user asks for reduced motion (`MediaQuery.disableAnimations`), a
  short, calm version plays instead: no flash, no shake, nothing flying; the
  title fades in. Set your own with `CelebrationConfig.reducedMotion`.
- The title is announced to screen readers.
- Everything runs off one `AnimationController`, so `timeDilation` slows it
  all down together.
- Particles are pure functions of time with prebuilt paints, paths and colour
  tables; each layer sits in its own `RepaintBoundary`.

## Example

The [example app](example/) has a gallery of every tier, a playground to build
your own (effects, length, colours, brand, sound, scrubbing) and a slow-motion
switch.

## Check out other Yako packages:

[Badges](https://pub.dev/packages/badges)

[Settings UI](https://pub.dev/packages/settings_ui)

[Status Alert](https://pub.dev/packages/status_alert)

[Full Screen Menu](https://pub.dev/packages/full_screen_menu)

[Diagonal decoration](https://pub.dev/packages/diagonal_decoration)

[Theme Switch](https://pub.dev/packages/yako_theme_switch)

and more to come!
