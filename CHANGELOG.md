## [1.0.1] - [Sep 26, 2026]

* README: a **More from Yako** grid with an animated preview of each of our other packages.

## [1.0.0] - [Sep 26, 2026]

* First release.
* `YakoCelebration.show(context, tier: ...)`: a full-screen celebration in one
  line, over everything, without blocking touches.
* Five ready-made tiers, each bigger and longer than the last: `subtle`,
  `nice`, `great`, `epic`, `legendary`.
* `CelebrationTier.custom(CelebrationConfig(...))`: pick your own effects,
  length, colours, title, sound, haptics and background dim. Every preset is a
  plain `CelebrationConfig` you can `copyWith`.
* A second ladder built from designer-made Lottie animations:
  `lottieSubtle`, `lottieNice`, `lottieGreat`, `lottieEpic`,
  `lottieLegendary` (`CelebrationTier.lottieValues`), with a light-sweep
  title, vignette, flash and shake. Eight Lottie files ship with the package
  under the Lottie Simple License (see `assets/lottie/LICENSE.md`).
* `LottieEffect`: play a bundled animation or your own Lottie file on the
  celebration's clock, placed with `LottieAnchor`, tinted, spun or faded.
* Code-drawn effects: flames, spinning coins, confetti,
  streamers, fireworks, sparkles, light rays, your brand icon popping up in a
  storm, a wall of fire, title slam with subtitle, camera flash, screen shake
  and edge glow. Palettes: gold, fire, party, rainbow and your accent colour.
* `extraLayers` to add your own widgets on the same clock.
* `CelebrationBrand`: your name and icon (widget or image), per call or
  app-wide with `YakoCelebration.configure`.
* Built-in sounds for every tier, synthesised by the package's own script, so
  you can ship them anywhere. Override per call or per tier with an asset, a
  file or a URL, turn them off, mute globally, or play them with your own
  audio stack via `onPlaySound`. Sounds are preloaded.
* Haptic patterns on the celebration's clock, using Flutter's
  `HapticFeedback` (no plugin).
* `CelebrationOverlay` + `CelebrationController` for celebrations inside one
  part of the screen; `CelebrationShaker` to shake your own content.
* `CelebrationPreview` to draw any moment of a celebration (scrubbers,
  previews, screenshots).
* Respects reduced motion (`MediaQuery.disableAnimations`) with a short, calm
  version; one master clock, so slow motion (`timeDilation`) and tests see the
  same frame.
