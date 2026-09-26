/// Full-screen celebration overlays in one line: flames, coins, confetti,
/// fireworks, your own brand icon popping, title slam, flash, shake, sound and
/// haptics.
///
/// ```dart
/// YakoCelebration.show(context, tier: CelebrationTier.epic);
/// ```
library;

export 'src/api.dart' show YakoCelebration;
export 'src/brand.dart' show CelebrationBrand;
export 'src/config.dart' show CelebrationConfig, CelebrationLayerBuilder;
export 'src/effects.dart'
    show
        BrandPopEffect,
        CelebrationArea,
        CelebrationEffect,
        CoinsEffect,
        ConfettiEffect,
        ConfettiLaunch,
        EdgeGlowEffect,
        FireWallEffect,
        FireworksEffect,
        FlamesEffect,
        FlashEffect,
        LightRaysEffect,
        ShakeEffect,
        SparklesEffect,
        StreamersEffect,
        TitleSlamEffect;
export 'src/engine/run.dart' show CelebrationHandle;
export 'src/haptics.dart'
    show CelebrationHapticKind, CelebrationHaptics, HapticPulse;
export 'src/palette.dart' show CelebrationPalette;
export 'src/sound.dart'
    show
        AssetCelebrationSound,
        BuiltInCelebrationSound,
        CelebrationSound,
        CelebrationSoundHandler,
        FileCelebrationSound,
        NoCelebrationSound,
        UrlCelebrationSound;
export 'src/tier.dart' show CelebrationTier;
export 'src/widgets.dart'
    show
        CelebrationController,
        CelebrationOverlay,
        CelebrationPreview,
        CelebrationShaker;
