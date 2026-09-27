"""Generates the night ambience (assets/audio/ambience/night.ogg): a seamless
48 s loop of crickets only. Two voices chirp in bouts (a few seconds of
chirping, then a longer rest) so it never becomes a constant texture.
No continuous noise bed or water sounds: both were tried and rejected.
Run from the repo root:  python3 tools/audio/ambience.py
"""
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


if __name__ == "__main__":
    write_ogg(OUT + "night.ogg", night(), 4)
