"""Generates the biome ambiences (assets/audio/ambience/<name>.ogg): seamless
48 s loops made only of sparse events in bouts with long rests, so none of them
becomes a constant texture. No continuous noise bed, wind or flowing water:
those were tried and rejected by the owner.

  night.ogg   Night Forest   crickets
  swamp.ogg   Glowing Swamp  bubbles surfacing
  caves.ogg   Crystal Caves  echoing drips + a rare crystal chime
  ash.ogg     Ash Forest     isolated ember crackles
  frozen.ogg  Frozen Vale    ice tinkles + a rare distant howl
  ruins.ogg   Sunken Ruins   a drowned temple bell, muffled by the water + bubble trains

Run from the repo root:  python3 tools/audio/ambience.py [name ...]
"""
import sys
from synth import *  # noqa: F401,F403

OUT = "assets/audio/ambience/"
LENGTH = 48.0


def chirp(freq, pulses):
    pulse_d, gap = 0.014, 0.034
    out = np.zeros(int((pulses * gap + 0.05) * SR))
    n = int(pulse_d * SR)
    for k in range(pulses):
        p = sine(freq, pulse_d) * np.sin(np.pi * np.arange(n) / n)
        mix_into(out, k * gap, p, wrap=False)
    return out


def night():
    out = np.zeros(int(LENGTH * SR))
    rng = np.random.default_rng(3)
    # (pitch, seconds between chirps inside a bout, bout length, rest length, gain)
    voices = [(4300, 1.4, (3, 6), (12, 20), 0.10), (4900, 2.0, (2, 5), (16, 24), 0.06)]
    for freq, period, bout, rest, gain in voices:
        pos = rng.uniform(0, 6)
        while pos < LENGTH - 1:
            bout_end = pos + rng.uniform(*bout)
            while pos < min(bout_end, LENGTH - 1):
                mix_into(out, pos, chirp(freq * rng.uniform(0.99, 1.01), int(rng.integers(2, 4))),
                         gain * rng.uniform(0.6, 1.0))
                pos += period * rng.uniform(0.85, 1.3)
            pos += rng.uniform(*rest)
    return normalize(out, -8.0)


def echo(x, delay, feedback, taps=4, cutoff=2500):
    """Feedback-like echo: each repeat quieter and darker (wraps: loop-safe)."""
    out = x.copy()
    tap = x
    for k in range(1, taps + 1):
        tap = lowpass(tap, cutoff) * feedback
        mix_into(out, delay * k, tap)
    return out


def bubble(f0=300, f1=900, d=0.05):
    return sine(sweep(f0, f1, d), d) * env_exp(d, 0.02, attack=0.003)


def blub(rng, size=1.0):
    """A swamp bubble surfacing: a short sine whose pitch rises a little as it
    decays (Minnaert resonance); bigger bubbles are lower and longer."""
    f = rng.uniform(260, 520) / size
    d = 0.06 * size
    freq = f * (1 + 0.25 * np.linspace(0, 1, int(d * SR)))
    return sine(freq, d) * env_exp(d, 0.018 * size, attack=0.002)


def swamp_bubbles(rng, per_minute):
    """Bubbles alone or in little "blub-blub" groups, at random times."""
    out = np.zeros(int(LENGTH * SR))
    pos = rng.uniform(0, 3)
    while pos < LENGTH:
        for _ in range(int(rng.choice([1, 1, 2, 3]))):
            mix_into(out, pos, blub(rng, rng.uniform(0.8, 1.8)), rng.uniform(0.3, 0.6))
            pos += rng.uniform(0.08, 0.3)
        pos += rng.exponential(60 / per_minute)
    return out


def swamp():
    """Bubbles surfacing alone or in little groups, ~26 per minute."""
    rng = np.random.default_rng(6)
    return normalize(swamp_bubbles(rng, 26), -8.0)


def drip(freq):
    d = 0.09
    return sine(sweep(freq, freq * 1.9, d, 0.5), d) * env_exp(d, 0.03, attack=0.001)


def chime(freq, d=2.2):
    partials = [(1.0, 1.0), (2.76, 0.5), (5.40, 0.25), (8.93, 0.12)]
    x = sum(sine(freq * r, d) * g * env_exp(d, d / (2 + 3 * r)) for r, g in partials)
    return x


def caves():
    out = np.zeros(int(LENGTH * SR))
    rng = np.random.default_rng(7)
    pos = rng.uniform(0, 2)
    while pos < LENGTH:
        # A few drips close together, then silence.
        for _ in range(int(rng.integers(1, 4))):
            mix_into(out, pos, echo(drip(rng.uniform(700, 1300)), 0.23, 0.45), rng.uniform(0.3, 0.6))
            pos += rng.uniform(0.6, 1.8)
        pos += rng.uniform(4, 9)
    for start in (rng.uniform(8, 18), rng.uniform(30, 42)):
        mix_into(out, start, echo(chime(rng.choice([1568, 1760, 2093])), 0.31, 0.35, cutoff=4000), 0.18)
    return normalize(out, -8.0)


def crackle(rng):
    d = rng.uniform(0.004, 0.012)
    return bandpass(noise(d), 1200, 5000) * env_exp(d, d / 3, attack=0.0005)


def ash():
    out = np.zeros(int(LENGTH * SR))
    rng = np.random.default_rng(11)
    pos = rng.uniform(0, 2)
    while pos < LENGTH:
        # A small cluster of pops (an ember snapping), then quiet.
        for _ in range(int(rng.integers(1, 5))):
            mix_into(out, pos, crackle(rng), rng.uniform(0.3, 1.0))
            pos += rng.uniform(0.02, 0.18)
        pos += rng.exponential(1.6) + 0.4
    # A low, soft "whump" of a log settling, twice per loop.
    for start in (rng.uniform(5, 20), rng.uniform(28, 44)):
        thump = lowpass(noise(0.4), 180) * env_exp(0.4, 0.12, attack=0.02)
        mix_into(out, start, thump, 2.5)
    return normalize(out, -9.0)


def tinkle(rng):
    d = 0.25
    f = rng.uniform(2600, 4200)
    return (sine(f, d) + 0.3 * sine(f * 2.3, d)) * env_exp(d, 0.05, attack=0.001)


def howl(d=3.2):
    n = int(d * SR)
    k = np.arange(n) / n
    pitch = 380 + 220 * np.sin(np.pi * np.clip(k * 1.3, 0, 1)) + 6 * np.sin(2 * np.pi * 5 * k * d)
    phase = 2 * np.pi * np.cumsum(pitch) / SR
    x = np.sin(phase) + 0.3 * np.sin(2 * phase) + 0.1 * np.sin(3 * phase)
    return lowpass(x * np.sin(np.pi * k) ** 1.5, 1400)


def frozen():
    out = np.zeros(int(LENGTH * SR))
    rng = np.random.default_rng(13)
    pos = rng.uniform(0, 3)
    while pos < LENGTH:
        for _ in range(int(rng.integers(2, 6))):
            mix_into(out, pos, tinkle(rng), rng.uniform(0.15, 0.4))
            pos += rng.uniform(0.05, 0.25)
        pos += rng.uniform(3, 8)
    mix_into(out, rng.uniform(18, 26), echo(howl(), 0.4, 0.35, cutoff=1000), 0.22)
    return normalize(out, -8.0)


def sunken_bell(freq, d=4.0):
    """A bell of the drowned temple heard through water: inharmonic partials
    (audible on small speakers, unlike a pure low pulse), a slow swell instead
    of a sharp strike, and a muffled top end."""
    partials = [(0.5, 0.5), (1.0, 1.0), (2.0, 0.45), (2.76, 0.3), (4.1, 0.15)]
    x = sum(sine(freq * r, d) * g * env_exp(d, d / (1.5 + r), attack=0.08) for r, g in partials)
    # Slow wobble, as if the sound bends through the currents.
    wobble = 1 + 0.15 * np.sin(2 * np.pi * 0.7 * np.arange(len(x)) / SR)
    return lowpass(x * wobble, 900)


def ruins():
    out = np.zeros(int(LENGTH * SR))
    rng = np.random.default_rng(17)
    pos = rng.uniform(1, 4)
    while pos < LENGTH:
        mix_into(out, pos, echo(sunken_bell(rng.choice([196, 220, 262])), 0.45, 0.4, taps=3, cutoff=700), 1.0)
        pos += rng.uniform(9, 14)
    pos = rng.uniform(2, 5)
    while pos < LENGTH:
        # A train of rising bubbles.
        for _ in range(int(rng.integers(3, 8))):
            mix_into(out, pos, lowpass(bubble(rng.uniform(250, 400), rng.uniform(600, 900), 0.06), 1800),
                     rng.uniform(0.4, 0.7))
            pos += rng.uniform(0.08, 0.3)
        pos += rng.uniform(4, 8)
    return normalize(out, -8.0)


def lufs(x):
    """Integrated loudness (EBU R128) measured by ffmpeg."""
    import re
    import subprocess
    import tempfile
    from scipy.io import wavfile
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        wavfile.write(tmp.name, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
        log = subprocess.run(["ffmpeg", "-nostats", "-i", tmp.name, "-af", "ebur128", "-f", "null", "-"],
                             capture_output=True, text=True).stderr
    return float(re.findall(r"I:\s+(-?[\d.]+) LUFS", log)[-1])


def match_loudness(x, target=-25.0, max_peak_db=-1.0):
    """Brings every ambience to the night ambience's loudness (peaks limited)."""
    y = x * 10 ** ((target - lufs(x)) / 20)
    ceiling = 10 ** (max_peak_db / 20)
    if np.max(np.abs(y)) > ceiling:
        y = soft_clip(y / ceiling, 1.5) * ceiling
    return y


# Loudness of each ambience (LUFS). Night is the reference (-25); sparse clicks
# (ash) sound louder than they measure, so they sit a bit lower.
LOUDNESS = {"night": None, "swamp": -27.0, "caves": -25.0, "ash": -33.0, "frozen": -26.0, "ruins": -22.5}

RECIPES = {"night": night, "swamp": swamp, "caves": caves, "ash": ash, "frozen": frozen, "ruins": ruins}

if __name__ == "__main__":
    for name in sys.argv[1:] or RECIPES:
        x = RECIPES[name]()
        if LOUDNESS[name] is not None:
            x = match_loudness(x, LOUDNESS[name])
        write_ogg(OUT + name + ".ogg", x, 4)
