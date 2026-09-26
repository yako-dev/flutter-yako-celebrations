## [0.1.0] - [Sep 26, 2026]

* First release.
* `YakoCelebration.show(context, tier: ...)`: a full-screen celebration in one
  line, over everything, without blocking touches.
* Five ready-made tiers, each bigger and longer than the last: `subtle`,
  `nice`, `great`, `epic`, `legendary`.
* `CelebrationTier.custom(CelebrationConfig(...))`: pick your own effects,
  length, colours, title, sound, haptics and background dim. Every preset is a
  plain `CelebrationConfig` you can `copyWith`.
* Effects, all drawn in code (no Lottie): flames, spinning coins, confetti,
  streamers, fireworks, sparkles, light rays, your brand icon popping up in a
  storm, a wall of fire, title slam with subtitle, camera flash, screen shake
  and edge glow. Palettes: gold, fire, party, rainbow and your accent colour.
* `extraLayers` to add your own widgets (for example your own Lottie) on the
  same clock.
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
