# yako_celebrations example

A gallery of every ready-made tier, in both styles, and a playground to build
your own celebration.

```bash
flutter run
```

- **Gallery**: tap a tier to celebrate. Switch between the Classic tiers
  (drawn in code) and the Lottie tiers. The buttons in the top bar play
  everything in slow motion and turn the sound on or off.
- **Playground**: pick effects, length, colours, brand and sound, scrub
  through the result, then celebrate.

The brand is the Yako icon from `assets/yako_logo.png`, passed as
`CelebrationBrand(image: AssetImage(...))`: put your own icon there. The
package itself ships no icon.

`assets/level_up.mp3` is the "custom sound" demo; like the package's own
sounds it is synthesised by `tool/generate_sounds.py`.

For README images, `--dart-define=SHOTS=legendary@0.3` freezes tiers and
`--dart-define=DEMO=legendary` plays them, both on an empty dark screen.
