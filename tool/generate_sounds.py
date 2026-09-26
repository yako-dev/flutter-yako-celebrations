#!/usr/bin/env python3
"""Synthesises every built-in yako_celebrations sound from scratch.

Nothing here is sampled or downloaded: each sound is plain maths (sines,
filtered noise, envelopes and a synthetic reverb), so the package owns every
byte of the output.

    python3 tool/generate_sounds.py            # writes assets/sounds/*.mp3
    python3 tool/generate_sounds.py --wav      # also keeps the .wav files

Needs Python 3.9+, numpy, and `lame` or `ffmpeg` on PATH for the MP3 step.
Output is deterministic (fixed seeds), so re-running gives the same audio.

Tier lengths and the moment of the big hit live in `tool/sound_timings.json`.
The Dart presets read the same numbers in a test, so the sound always lasts as
long as the celebration it belongs to.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

SR = 44100
ROOT = Path(__file__).resolve().parent.parent
TIMINGS = json.loads((ROOT / "tool" / "sound_timings.json").read_text())


# --------------------------------------------------------------------------
# Building blocks
# --------------------------------------------------------------------------


def samples(seconds: float) -> int:
    return max(1, int(round(seconds * SR)))


def t_axis(seconds: float) -> np.ndarray:
    return np.arange(samples(seconds)) / SR


def mix(buf: np.ndarray, sig: np.ndarray, at: float, gain: float = 1.0) -> None:
    """Adds `sig` into `buf` starting at `at` seconds (clipped to the end)."""
    i = samples(at) if at > 0 else 0
    if i >= len(buf):
        return
    j = min(len(buf), i + len(sig))
    buf[i:j] += gain * sig[: j - i]


def fade_in(sig: np.ndarray, seconds: float = 0.003) -> np.ndarray:
    n = min(len(sig), samples(seconds))
    sig[:n] *= np.linspace(0.0, 1.0, n)
    return sig


def fade_out(sig: np.ndarray, seconds: float) -> np.ndarray:
    n = min(len(sig), samples(seconds))
    sig[-n:] *= np.linspace(1.0, 0.0, n) ** 2
    return sig


def spectral_filter(sig: np.ndarray, low: float | None = None,
                    high: float | None = None, order: int = 2) -> np.ndarray:
    """Zero-phase Butterworth-shaped band filter done in the frequency domain."""
    n = len(sig)
    spec = np.fft.rfft(sig)
    freqs = np.fft.rfftfreq(n, 1.0 / SR)
    gain = np.ones_like(freqs)
    if high is not None:
        gain *= 1.0 / np.sqrt(1.0 + (freqs / high) ** (2 * order))
    if low is not None:
        with np.errstate(divide="ignore"):
            ratio = np.where(freqs > 0, low / np.maximum(freqs, 1e-9), 1e9)
        gain *= 1.0 / np.sqrt(1.0 + ratio ** (2 * order))
    return np.fft.irfft(spec * gain, n)


def sweep_phase(freq: np.ndarray) -> np.ndarray:
    """Phase for an oscillator whose frequency changes every sample."""
    return 2.0 * np.pi * np.cumsum(freq) / SR


def reverb(sig: np.ndarray, rng: np.random.Generator, seconds: float = 1.6,
           decay: float = 0.42, wet: float = 0.25, tone: float = 6000.0) -> np.ndarray:
    """Convolves with synthetic, exponentially decaying noise (a small hall)."""
    t = t_axis(seconds)
    ir = rng.standard_normal(len(t)) * np.exp(-t / decay)
    ir = spectral_filter(ir, low=200.0, high=tone)
    ir[: samples(0.012)] = 0.0  # a short pre-delay keeps the hits crisp
    ir /= np.sqrt(np.sum(ir ** 2))
    n = len(sig) + len(ir) - 1
    size = 1 << (n - 1).bit_length()
    wet_sig = np.fft.irfft(np.fft.rfft(sig, size) * np.fft.rfft(ir, size), size)
    return sig + wet * wet_sig[: len(sig)]


# --------------------------------------------------------------------------
# Instruments
# --------------------------------------------------------------------------


def bell(freq: float, seconds: float = 1.4, tau: float = 0.45,
         bright: float = 1.0, rng: np.random.Generator | None = None) -> np.ndarray:
    """A glassy chime: inharmonic partials, the high ones dying first."""
    t = t_axis(seconds)
    partials = [
        (1.00, 1.00, 1.00),
        (2.00, 0.55, 0.70),
        (2.76, 0.40, 0.50),
        (4.07, 0.26, 0.36),
        (5.43, 0.16 * bright, 0.26),
        (8.93, 0.10 * bright, 0.16),
    ]
    out = np.zeros_like(t)
    for ratio, amp, life in partials:
        f = freq * ratio
        if f > SR * 0.45:
            continue
        phase = 0.0 if rng is None else rng.uniform(0, 2 * np.pi)
        out += amp * np.sin(2 * np.pi * f * t + phase) * np.exp(-t / (tau * life))
    return fade_in(out)


def glitter(seconds: float, rng: np.random.Generator, density: float = 40.0,
            low: float = 3000.0, high: float = 8000.0, rising: bool = True,
            amp: float = 0.22) -> np.ndarray:
    """Tiny random high blips: the sound of sparkles."""
    out = np.zeros(samples(seconds))
    count = int(density * seconds)
    for _ in range(count):
        at = rng.uniform(0, seconds * 0.92)
        progress = at / seconds
        lo = low + (high - low) * (0.35 * progress if rising else 0.0)
        f = rng.uniform(lo, high)
        blip_t = t_axis(0.07)
        blip = np.sin(2 * np.pi * f * blip_t) * np.exp(-blip_t / rng.uniform(0.01, 0.025))
        fall_off = (1.0 - progress) ** 1.2
        mix(out, fade_in(blip, 0.001), at, amp * rng.uniform(0.4, 1.0) * fall_off)
    return out


def coin(rng: np.random.Generator) -> np.ndarray:
    """A small metallic 'ting' with a click on the front."""
    f1 = rng.uniform(3600, 4700)
    t = t_axis(0.22)
    body = (np.sin(2 * np.pi * f1 * t) * np.exp(-t / rng.uniform(0.04, 0.08))
            + 0.6 * np.sin(2 * np.pi * f1 * 1.47 * t) * np.exp(-t / 0.035)
            + 0.3 * np.sin(2 * np.pi * f1 * 2.31 * t) * np.exp(-t / 0.02))
    click = spectral_filter(rng.standard_normal(len(t)), low=4000) * np.exp(-t / 0.002)
    return fade_in(body * 0.7 + click * 0.25, 0.0005)


def coin_shower(seconds: float, rng: np.random.Generator, count: int,
                start: float = 0.0) -> np.ndarray:
    out = np.zeros(samples(start + seconds))
    for _ in range(count):
        # More coins early, thinning out like the visual rain.
        at = start + seconds * rng.beta(1.3, 2.2)
        mix(out, coin(rng), at, rng.uniform(0.15, 0.45))
    return out


def brass(freq: float, seconds: float, rng: np.random.Generator,
          attack: float = 0.05, release: float = 0.35) -> np.ndarray:
    """A warm fanfare voice. Brightness follows loudness, like a real horn."""
    t = t_axis(seconds)
    n = len(t)
    env = np.ones(n)
    a = samples(attack)
    d = samples(0.18)
    r = samples(release)
    env[:a] = np.linspace(0, 1, a) ** 1.5
    env[a:a + d] = np.linspace(1.0, 0.78, len(env[a:a + d]))
    env[a + d:] = 0.78
    env[-r:] *= np.linspace(1, 0, r) ** 2
    vibrato = 1.0 + 0.0035 * np.sin(2 * np.pi * 5.3 * t) * np.clip((t - 0.2) * 3, 0, 1)
    out = np.zeros(n)
    for detune in (-0.0025, 0.0, 0.0025):
        phase = sweep_phase(freq * (1 + detune) * vibrato) + rng.uniform(0, 2 * np.pi)
        harmonic = 1
        while harmonic * freq < 9000 and harmonic <= 14:
            weight = env ** (1.0 + 0.32 * (harmonic - 1)) / harmonic ** 1.05
            out += weight * np.sin(harmonic * phase)
            harmonic += 1
    return out / 3.0


def chord(freqs: list[float], seconds: float, rng: np.random.Generator,
          **kwargs) -> np.ndarray:
    return sum(brass(f, seconds, rng, **kwargs) for f in freqs) / len(freqs)


def boom(rng: np.random.Generator, size: float = 1.0) -> np.ndarray:
    """A deep impact: falling sine thump, a noise body and a click."""
    seconds = 0.9 + 0.6 * size
    t = t_axis(seconds)
    freq = 38 + 95 * np.exp(-t / 0.07)
    thump = np.sin(sweep_phase(freq)) * np.exp(-t / (0.28 + 0.2 * size))
    body = spectral_filter(rng.standard_normal(len(t)), high=380 + 200 * size)
    body *= np.exp(-t / (0.09 + 0.06 * size))
    click = spectral_filter(rng.standard_normal(len(t)), low=1500) * np.exp(-t / 0.004)
    return fade_in(thump * 1.0 + body * 1.4 + click * 0.35, 0.001)


def riser(seconds: float, rng: np.random.Generator, top: float = 1400.0) -> np.ndarray:
    """A whoosh that climbs into the hit."""
    t = t_axis(seconds)
    shape = (t / seconds) ** 2.2
    noise = spectral_filter(rng.standard_normal(len(t)), low=700, high=7000)
    freq = 180 * (top / 180) ** (t / seconds)
    tone = np.sin(sweep_phase(freq)) + 0.35 * np.sin(2 * sweep_phase(freq))
    out = 0.55 * noise * shape + 0.25 * tone * shape
    out[-samples(0.01):] *= np.linspace(1, 0, samples(0.01))
    return out


def pop(rng: np.random.Generator) -> np.ndarray:
    """A confetti-cannon / firework 'pop'."""
    t = t_axis(0.35)
    noise = spectral_filter(rng.standard_normal(len(t)), low=120, high=2200)
    thump = np.sin(2 * np.pi * 85 * t) * np.exp(-t / 0.05)
    return fade_in(noise * np.exp(-t / 0.028) * 1.1 + thump * 0.8, 0.0008)


def crackle(seconds: float, rng: np.random.Generator, count: int = 45) -> np.ndarray:
    """The fizzing tail after a firework bursts."""
    out = np.zeros(samples(seconds))
    for _ in range(count):
        at = seconds * rng.beta(1.2, 2.6)
        n = samples(rng.uniform(0.002, 0.006))
        click = spectral_filter(rng.standard_normal(n + 64), low=2500)[:n]
        click *= np.exp(-np.arange(n) / (n / 3))
        mix(out, click, at, rng.uniform(0.1, 0.35))
    return out


def whistle(seconds: float, rng: np.random.Generator) -> np.ndarray:
    """A rising shell."""
    t = t_axis(seconds)
    freq = 900 * (2.4 ** (t / seconds)) * (1 + 0.01 * np.sin(2 * np.pi * 9 * t))
    env = np.sin(np.pi * np.clip(t / seconds, 0, 1)) ** 0.6
    air = spectral_filter(rng.standard_normal(len(t)), low=2000, high=6000) * 0.25
    return (np.sin(sweep_phase(freq)) * 0.5 + air) * env


def firework(rng: np.random.Generator, rise: float = 0.55) -> np.ndarray:
    out = np.zeros(samples(rise + 1.4))
    mix(out, whistle(rise, rng), 0.0, 0.18)
    mix(out, pop(rng), rise, 0.9)
    mix(out, crackle(1.1, rng), rise + 0.12, 0.8)
    return out


def fire_roar(seconds: float, rng: np.random.Generator) -> np.ndarray:
    """A soft bed of burning: brown noise with a slow, uneven swell."""
    t = t_axis(seconds)
    brown = np.cumsum(rng.standard_normal(len(t)))
    brown = spectral_filter(brown, low=40, high=700)
    brown /= np.max(np.abs(brown)) + 1e-9
    lfo = 0.65 + 0.2 * np.sin(2 * np.pi * 3.1 * t) + 0.15 * np.sin(2 * np.pi * 7.7 * t + 1)
    env = np.clip(t / 0.4, 0, 1) * np.clip((seconds - t) / 1.2, 0, 1)
    out = brown * lfo * env
    mix(out, crackle(seconds, rng, count=int(seconds * 14)), 0.0, 0.5)
    return out


def shimmer(freqs: list[float], seconds: float, rng: np.random.Generator) -> np.ndarray:
    """A soft, wide pad of detuned sines for the 'rainbow' moments."""
    t = t_axis(seconds)
    out = np.zeros(len(t))
    for f in freqs:
        for detune in (-0.004, 0.0, 0.004):
            trem = 0.75 + 0.25 * np.sin(2 * np.pi * rng.uniform(4, 7) * t + rng.uniform(0, 6))
            out += np.sin(2 * np.pi * f * (1 + detune) * t + rng.uniform(0, 6)) * trem
    env = np.clip(t / 0.35, 0, 1) * np.clip((seconds - t) / 1.0, 0, 1) ** 1.5
    return out * env / (3 * len(freqs))


def square_blip(freq: float, seconds: float) -> np.ndarray:
    """A retro 8-bit note (used for the example app's 'custom' sound)."""
    t = t_axis(seconds)
    wave_ = np.sign(np.sin(2 * np.pi * freq * t)) * 0.5
    wave_ = spectral_filter(wave_, high=5000)
    return fade_out(fade_in(wave_ * np.exp(-t / (seconds * 0.8))), 0.02)


# --------------------------------------------------------------------------
# Notes
# --------------------------------------------------------------------------


def note(name: str) -> float:
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    base = names[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        base += 1
        rest = rest[1:]
    elif rest.startswith("b"):
        base -= 1
        rest = rest[1:]
    octave = int(rest)
    return 440.0 * 2 ** ((base + 12 * (octave - 4)) / 12)


# --------------------------------------------------------------------------
# Tiers
# --------------------------------------------------------------------------


def render_subtle(spec: dict, rng: np.random.Generator) -> np.ndarray:
    out = np.zeros(samples(spec["duration"]))
    hit = spec["impact"]
    mix(out, bell(note("E6"), 1.0, tau=0.3, rng=rng), hit, 0.55)
    mix(out, bell(note("B6"), 0.9, tau=0.25, rng=rng), hit + 0.07, 0.4)
    mix(out, glitter(0.7, rng, density=30, amp=0.16), hit, 1.0)
    return reverb(out, rng, seconds=0.9, decay=0.22, wet=0.22)


def render_nice(spec: dict, rng: np.random.Generator) -> np.ndarray:
    out = np.zeros(samples(spec["duration"]))
    hit = spec["impact"]
    for i, name in enumerate(["C6", "E6", "G6"]):
        mix(out, bell(note(name), 1.2, tau=0.35, rng=rng), hit + i * 0.085, 0.45)
    mix(out, bell(note("C7"), 1.6, tau=0.55, rng=rng), hit + 0.27, 0.5)
    mix(out, pop(rng), max(0.0, hit - 0.02), 0.35)
    mix(out, glitter(1.4, rng, density=34, amp=0.18), hit + 0.1, 1.0)
    return reverb(out, rng, seconds=1.2, decay=0.3, wet=0.25)


def render_great(spec: dict, rng: np.random.Generator) -> np.ndarray:
    out = np.zeros(samples(spec["duration"]))
    hit = spec["impact"]
    mix(out, riser(hit, rng, top=1100), 0.0, 0.35)
    mix(out, pop(rng), hit - 0.01, 0.8)
    mix(out, pop(rng), hit + 0.05, 0.6)
    for i, name in enumerate(["C5", "E5", "G5", "C6"]):
        mix(out, bell(note(name), 1.3, tau=0.4, rng=rng), hit + i * 0.075, 0.38)
    mix(out, chord([note("C4"), note("E4"), note("G4"), note("C5")], 1.6, rng),
        hit + 0.28, 0.75)
    mix(out, glitter(2.2, rng, density=36, amp=0.2), hit + 0.2, 1.0)
    mix(out, coin_shower(1.6, rng, count=10, start=0.0), hit + 0.4, 0.8)
    return reverb(out, rng, seconds=1.5, decay=0.38, wet=0.26)


def render_epic(spec: dict, rng: np.random.Generator) -> np.ndarray:
    out = np.zeros(samples(spec["duration"]))
    hit = spec["impact"]
    mix(out, riser(hit, rng, top=1600), 0.0, 0.5)
    mix(out, boom(rng, size=0.8), hit, 0.95)
    mix(out, chord([note("G3"), note("B3"), note("D4"), note("G4")], 0.55, rng),
        hit + 0.02, 0.8)
    mix(out, chord([note("C4"), note("E4"), note("G4"), note("C5")], 2.3, rng),
        hit + 0.55, 0.85)
    for i, name in enumerate(["G5", "C6", "E6", "G6"]):
        mix(out, bell(note(name), 1.3, tau=0.4, rng=rng), hit + 0.55 + i * 0.07, 0.3)
    mix(out, coin_shower(2.6, rng, count=34), hit + 0.2, 0.9)
    for at in spec.get("fireworks", []):
        mix(out, firework(rng, rise=0.5), at - 0.5, 0.5)
    mix(out, glitter(3.2, rng, density=30, amp=0.18), hit + 0.4, 1.0)
    return reverb(out, rng, seconds=1.9, decay=0.46, wet=0.27)


def render_legendary(spec: dict, rng: np.random.Generator) -> np.ndarray:
    total = spec["duration"]
    out = np.zeros(samples(total))
    hit = spec["impact"]
    mix(out, riser(hit, rng, top=2000), 0.0, 0.6)
    mix(out, boom(rng, size=1.3), hit, 1.1)
    mix(out, pop(rng), hit + 0.01, 0.7)
    mix(out, fire_roar(total - hit - 0.4, rng), hit + 0.1, 0.32)
    progression = [
        ([note("C4"), note("E4"), note("G4"), note("C5")], 0.0, 0.62),
        ([note("F4"), note("A4"), note("C5"), note("F5")], 0.62, 0.62),
        ([note("G4"), note("B4"), note("D5"), note("G5")], 1.24, 0.62),
        ([note("C4"), note("G4"), note("C5"), note("E5"), note("G5")], 1.86, 2.6),
    ]
    for freqs, offset, length in progression:
        mix(out, chord(freqs, length + 0.25, rng), hit + 0.05 + offset, 0.8)
    for i, name in enumerate(["C6", "E6", "G6", "C7", "E7"]):
        mix(out, bell(note(name), 1.6, tau=0.5, rng=rng), hit + 1.9 + i * 0.07, 0.3)
    mix(out, shimmer([note("C6"), note("E6"), note("G6")], total - hit - 1.0, rng),
        hit + 0.6, 0.35)
    mix(out, coin_shower(4.2, rng, count=64), hit + 0.2, 0.9)
    for at in spec.get("fireworks", []):
        mix(out, firework(rng, rise=0.5), at - 0.5, 0.55)
    mix(out, glitter(total - hit - 1.2, rng, density=34, amp=0.2), hit + 1.0, 1.0)
    return reverb(out, rng, seconds=2.2, decay=0.55, wet=0.28)


def render_example_custom(rng: np.random.Generator) -> np.ndarray:
    """A retro 'level up' for the example app's custom-sound demo."""
    out = np.zeros(samples(1.4))
    for i, name in enumerate(["C5", "E5", "G5", "C6", "E6", "G6", "C7"]):
        mix(out, square_blip(note(name), 0.16), i * 0.075, 0.35)
    mix(out, square_blip(note("C7"), 0.6), 0.55, 0.3)
    return reverb(out, rng, seconds=0.8, decay=0.2, wet=0.15)


def with_bursts(base):
    """The Lottie ladder: a code-drawn tier's sound plus firework bursts (no
    whistle: the Lottie fireworks rise silently) at spec["bursts"]."""

    def render(spec: dict, rng: np.random.Generator) -> np.ndarray:
        out = base(spec, rng)
        for at in spec.get("bursts", []):
            burst = np.zeros(samples(1.4))
            mix(burst, pop(rng), 0.0, 0.9)
            mix(burst, crackle(1.1, rng), 0.12, 0.8)
            mix(out, burst, at, 0.45)
        return out

    return render


RENDERERS = {
    "subtle": render_subtle,
    "nice": render_nice,
    "great": render_great,
    "epic": render_epic,
    "legendary": render_legendary,
    "lottie_subtle": with_bursts(render_nice),
    "lottie_nice": with_bursts(render_nice),
    "lottie_great": with_bursts(render_great),
    "lottie_epic": with_bursts(render_epic),
    "lottie_legendary": with_bursts(render_legendary),
}


# --------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------


def master(sig: np.ndarray, peak_db: float, tail: float = 0.35) -> np.ndarray:
    sig = sig - np.mean(sig)
    sig = sig / (np.max(np.abs(sig)) + 1e-9)
    sig = np.tanh(1.4 * sig) / np.tanh(1.4)  # gentle soft clip
    sig = fade_out(sig, tail)
    return sig * 10 ** (peak_db / 20)


def write_wav(path: Path, sig: np.ndarray) -> None:
    pcm = np.clip(sig * 32767, -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def to_mp3(wav: Path, mp3: Path) -> None:
    if shutil.which("lame"):
        cmd = ["lame", "--quiet", "-m", "m", "-b", "96", "--noreplaygain",
               "--tt", mp3.stem, "--ta", "yako_celebrations", str(wav), str(mp3)]
    elif shutil.which("ffmpeg"):
        cmd = ["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav), "-ac", "1",
               "-b:a", "96k", "-map_metadata", "-1", str(mp3)]
    else:
        sys.exit("Need `lame` or `ffmpeg` on PATH to write MP3 files.")
    subprocess.run(cmd, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wav", action="store_true", help="keep .wav files too")
    args = parser.parse_args()

    build = ROOT / "tool" / "build"
    build.mkdir(parents=True, exist_ok=True)
    jobs = []
    for index, (name, render) in enumerate(RENDERERS.items()):
        spec = TIMINGS[name]
        sig = render(spec, np.random.default_rng(1000 + index))
        sig = master(sig[: samples(spec["duration"])], spec["peak_db"])
        jobs.append((ROOT / "assets" / "sounds" / f"{name}.mp3", sig))
    example = master(render_example_custom(np.random.default_rng(7)), -3.0, tail=0.2)
    jobs.append((ROOT / "example" / "assets" / "level_up.mp3", example))

    for target, sig in jobs:
        target.parent.mkdir(parents=True, exist_ok=True)
        wav = build / (target.stem + ".wav")
        write_wav(wav, sig)
        to_mp3(wav, target)
        if args.wav:
            shutil.copy(wav, target.with_suffix(".wav"))
        print(f"{target.relative_to(ROOT)}  {len(sig) / SR:.2f}s  "
              f"{target.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
