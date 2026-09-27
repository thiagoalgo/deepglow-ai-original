"""Generates the game's sound effects into assets/audio/sfx/*.ogg.

Retro-leaning but soft (no harsh square waves at full volume): each material
has its own timbre so a hit is recognisable without looking.
Run from the repo root:  python3 tools/audio/sfx.py
"""
from synth import *  # noqa: F401,F403

OUT = "assets/audio/sfx/"


def click(seconds=0.01, cutoff=4000.0):
    return highpass(noise(seconds), cutoff) * env_exp(seconds, 0.002)


def hit_wood():
    d = 0.14
    body = sine(sweep(210, 120, d), d) * env_exp(d, 0.035)
    knock = bandpass(noise(d), 500, 1600) * env_exp(d, 0.018)
    return body * 0.9 + knock * 0.7 + np.pad(click(0.01, 3000), (0, int(d * SR) - int(0.01 * SR))) * 0.3


def hit_stone():
    d = 0.12
    tick = bandpass(noise(d), 1800, 5000) * env_exp(d, 0.012)
    thud = sine(sweep(340, 200, d), d) * env_exp(d, 0.02)
    return tick * 0.9 + thud * 0.6


def hit_metal():
    d = 0.35
    ring = sum(sine(f, d) * env_exp(d, dec) * g for f, dec, g in
               [(1180, 0.12, 0.6), (1835, 0.08, 0.4), (2620, 0.05, 0.3)])
    return ring + bandpass(noise(d), 2500, 7000) * env_exp(d, 0.006) * 0.8


def hit_crystal():
    d = 0.6
    bell = sum(sine(note_hz(m), d) * env_exp(d, dec) * g for m, dec, g in
               [(96, 0.25, 0.5), (103, 0.18, 0.35), (108, 0.12, 0.25)])
    return bell + highpass(noise(d), 6000) * env_exp(d, 0.004) * 0.4


def hit_water():
    d = 0.16
    bloop = sine(sweep(260, 980, d, 0.6), d) * env_exp(d, 0.05, 0.004)
    splash = bandpass(noise(d), 1500, 6000) * env_exp(d, 0.03) * 0.35
    return bloop + splash


def hit_flesh():
    d = 0.16
    thud = sine(sweep(140, 60, d), d) * env_exp(d, 0.05)
    squish = lowpass(noise(d), 900) * env_exp(d, 0.04) * 0.9
    return thud + squish


def hit_plant():
    d = 0.12
    rustle = bandpass(noise(d), 2000, 7000) * env_exp(d, 0.04, 0.01)
    rustle *= 0.6 + 0.4 * np.sin(2 * np.pi * 70 * t(d))
    pop = sine(sweep(700, 400, d), d) * env_exp(d, 0.015) * 0.4
    return rustle + pop


# --- Boar (formant "voice": buzzy pulse source through mouth/nose resonators) ---

def _resonator(x, freq, bw):
    """2-pole resonator (a formant) whose centre frequency can glide."""
    out = np.zeros_like(x)
    y1 = y2 = 0.0
    freq = np.broadcast_to(freq, x.shape)
    r = np.exp(-np.pi * bw / SR)
    for i in range(len(x)):
        c = 2 * r * np.cos(2 * np.pi * freq[i] / SR)
        y = (1 - r) * x[i] + c * y1 - r * r * y2
        y2, y1 = y1, y
        out[i] = y
    return out


def _contour(points, seconds):
    xs = np.linspace(0, 1, int(seconds * SR))
    return np.interp(xs, [p[0] for p in points], [p[1] for p in points])


def _voice(seconds, f0_pts, formants, rough=0.0, rough_hz=30, breath=0.15, env=None):
    n = int(seconds * SR)
    f0 = _contour(f0_pts, seconds)
    f0 = f0 * (1 + 0.06 * lowpass(RNG.standard_normal(n), 40))       # jitter
    src = (np.cumsum(f0) / SR % 1.0) ** 3 * 2 - 1                     # buzzy pulse
    if rough:                                                         # growl
        src *= 1 - rough * (0.5 + 0.5 * np.sin(2 * np.pi * rough_hz * np.arange(n) / SR))
    src += breath * noise(seconds)
    out = sum(_resonator(src, _contour(pts, seconds), bw) * gain for pts, bw, gain in formants)
    return out * (env if env is not None else env_adsr(seconds, 0.01, 0.05, 0.8, seconds * 0.35))


def boar_grunt():
    """Spear hit on the boar: a nose snort + low, rough "hrrnk"."""
    d = 0.26
    snort = bandpass(noise(0.07), 600, 2500) * env_exp(0.07, 0.02) * 0.6
    body = _voice(d, [(0, 115), (0.3, 130), (1, 85)],
                  [([(0, 350), (1, 300)], 90, 1.0), ([(0, 900), (1, 750)], 120, 0.6),
                   ([(0, 2300), (1, 2200)], 200, 0.2)],
                  rough=0.7, rough_hz=28, breath=0.25)
    out = np.zeros(int((d + 0.05) * SR))
    mix_into(out, 0.0, snort, wrap=False)
    mix_into(out, 0.04, body, wrap=False)
    return out


def boar_squeal():
    """Final spear hit (boar collected): a short, comic high squeal."""
    d = 0.34
    return _voice(d, [(0, 700), (0.3, 1150), (1, 800)],
                  [([(0, 1000), (1, 900)], 180, 0.8), ([(0, 2200), (1, 2000)], 220, 1.0),
                   ([(0, 3300), (1, 3100)], 300, 0.4)],
                  rough=0.35, rough_hz=60, breath=0.2, env=env_adsr(d, 0.02, 0.08, 0.75, 0.12))


def blip(midi, d, duty=0.25, decay=None, cutoff=5000):
    x = square(note_hz(midi), d, duty) * env_exp(d, decay or d / 3, 0.001)
    return lowpass(x, cutoff)


def seq(notes, step, d=None, duty=0.25, cutoff=5000):
    d = d or step * 1.8
    total = step * (len(notes) - 1) + d
    out = np.zeros(int(total * SR) + 1)
    for i, m in enumerate(notes):
        mix_into(out, i * step, blip(m, d, duty, cutoff=cutoff), wrap=False)
    return out


def collect():
    return seq([84, 88, 91], 0.045, 0.12)


def buy():
    x = seq([79, 84, 88, 91, 96], 0.05, 0.16, duty=0.125)
    return x + np.pad(hit_crystal()[:len(x)] * 0.3, (0, max(0, len(x) - len(hit_crystal()))))[:len(x)]


def phase_start():
    d = 0.5
    rise = sine(sweep(220, 880, d, 2.0), d) * env_adsr(d, 0.05, 0.1, 0.7, 0.2) * 0.5
    chord = seq([69, 76, 81], 0.06, 0.35, duty=0.5, cutoff=3000)
    out = np.zeros(int(0.9 * SR))
    mix_into(out, 0.0, rise, wrap=False)
    mix_into(out, 0.42, chord, 0.8, wrap=False)
    return out


def phase_end():
    return seq([81, 76, 72, 69], 0.09, 0.3, duty=0.5, cutoff=2500)


def tick():
    return blip(93, 0.05, 0.5, 0.012, 6000)


def tick_last():
    return blip(100, 0.08, 0.5, 0.02, 7000)


def ui_move():
    return blip(88, 0.03, 0.25, 0.008, 4000) * 0.6


def ui_click():
    return seq([81, 88], 0.035, 0.06, duty=0.25, cutoff=4500)


def starving():
    d = 0.3
    return lowpass(square(note_hz(45), d, 0.5), 600) * env_exp(d, 0.12) * 0.8


SOUNDS = {
    "hit_wood": hit_wood, "hit_stone": hit_stone, "hit_metal": hit_metal,
    "hit_crystal": hit_crystal, "hit_water": hit_water, "hit_flesh": hit_flesh,
    "hit_plant": hit_plant, "collect": collect, "buy": buy,
    "phase_start": phase_start, "phase_end": phase_end, "tick": tick,
    "tick_last": tick_last, "ui_move": ui_move, "ui_click": ui_click,
    # Added later: kept last so the noise of the older sounds stays identical.
    "boar_grunt": boar_grunt, "boar_squeal": boar_squeal,
}

# Peak level per sound (dBFS): frequent/UI sounds sit lower than rewards.
PEAK_DB = {"boar_grunt": -4.0, "boar_squeal": -3.0,
           "ui_move": -14.0, "ui_click": -10.0, "tick": -9.0, "tick_last": -6.0,
           "collect": -7.0, "buy": -5.0, "phase_start": -5.0, "phase_end": -5.0}

if __name__ == "__main__":
    for name, fn in SOUNDS.items():
        peak = PEAK_DB.get(name, -7.0)
        write_ogg(OUT + name + ".ogg", fade_edges(normalize(fn(), peak), 2.0))
