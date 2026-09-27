"""Generates the music loops into assets/audio/music/*.ogg.

- phase_base / phase_rush: 132 BPM 90s-style acid techno, 32 bars in four
  sections that change key (A minor -> C minor -> D minor -> A minor).
  Both files have exactly the same length and are played in sync
  (AudioStreamSynchronized); "rush" (snare roll, high arp, siren) fades in
  when the phase timer runs low.
- camp: 112 BPM calmer loop (16 bars, second half one tone up) for menus.
Every note tail wraps around to the start, so the loops are seamless.
Run from the repo root:  python3 tools/audio/music.py
"""
from synth import *  # noqa: F401,F403

OUT = "assets/audio/music/"
BARS = 8


# --- Instruments -----------------------------------------------------------------

def kick(gain_click=0.3):
    d = 0.3
    body = sine(sweep(160, 42, d, 0.35), d) * env_exp(d, 0.14, 0.001)
    tick = highpass(noise(0.006), 3000) * gain_click
    return body + np.pad(tick, (0, len(body) - len(tick)))


def clap():
    d = 0.2
    out = np.zeros(int(d * SR))
    for k in range(3):
        burst = bandpass(noise(0.12), 900, 3200) * env_exp(0.12, 0.03 if k == 2 else 0.006)
        mix_into(out, k * 0.011, burst, wrap=False)
    return out


def hat(open_=False):
    d = 0.2 if open_ else 0.05
    return highpass(noise(d), 6500 if open_ else 8000, 3) * env_exp(d, 0.07 if open_ else 0.012)


def snare():
    d = 0.12
    return bandpass(noise(d), 1200, 6000) * env_exp(d, 0.035) + \
        sine(sweep(260, 180, d), d) * env_exp(d, 0.02) * 0.4


def stab(midis, d=0.22, cutoff=2600):
    x = sum(saw(note_hz(m) * det, d) for m in midis for det in (0.995, 1.005))
    return lowpass(x / (2 * len(midis)), cutoff) * env_exp(d, 0.09, 0.002)


def pluck(midi, d=0.25, duty=0.25, cutoff=3200):
    return lowpass(square(note_hz(midi), d, duty), cutoff) * env_exp(d, 0.06, 0.001)


def pad(midis, d, cutoff=1100):
    x = sum(saw(note_hz(m) * det, d) for m in midis for det in (0.993, 1.0, 1.007))
    return lowpass(x / (3 * len(midis)), cutoff) * env_adsr(d, d * 0.3, 0.1, 0.8, d * 0.3)


def acid_line(notes, accents, step, total, sweep_period=None):
    """16th-note acid bass: one saw with continuous phase, gated, resonant filter."""
    n = int(total * SR)
    freq = np.zeros(n)
    gate = np.zeros(n)
    cutoff = np.zeros(n)
    for i, (m, acc) in enumerate(zip(notes, accents)):
        a, b = int(i * step * SR), int((i + 1) * step * SR)
        seg = np.arange(b - a) / SR
        if m is None:
            freq[a:b] = freq[a - 1] if a else note_hz(33)
            continue
        freq[a:b] = note_hz(m)
        g = np.ones(b - a)
        g[int(len(g) * 0.7):] = np.linspace(1, 0, len(g) - int(len(g) * 0.7))
        gate[a:b] = g
        peak = 2600 if acc else 1300
        cutoff[a:b] = 220 + peak * np.exp(-seg / (0.09 if acc else 0.05))
    # Slow filter sweep (opens in the middle of each period, closes at its end).
    period = int((sweep_period or total) * SR)
    cutoff *= 0.7 + 0.5 * np.sin(np.pi * (np.arange(n) % period) / period)
    phase = np.cumsum(freq) / SR
    osc = 2.0 * (phase % 1.0) - 1.0
    return soft_clip(resonant_lowpass(osc * gate, cutoff, 0.85) * 1.6, 1.5)


def echo(x, delay_s, feedback=0.35, repeats=4):
    out = x.copy()
    for k in range(1, repeats + 1):
        out += np.roll(x, int(k * delay_s * SR)) * feedback ** k
    return out


# --- Tracks --------------------------------------------------------------------------

# Phase track sections (8 bars each): (key shift in semitones, variant).
# A minor -> C minor (lift) -> D minor (bridge) -> back to A minor (full).
PHASE_SECTIONS = [(0, "intro"), (3, "lift"), (5, "bridge"), (0, "full")]


def phase_tracks():
    bpm = 132
    beat = 60 / bpm
    step = beat / 4
    bars = 8 * len(PHASE_SECTIONS)
    total = bars * 4 * beat
    base = np.zeros(int(total * SR))
    rush = np.zeros(int(total * SR))
    roots = [0, 0, -4, -4, -2, -2, -5, -3]            # i i VI VI VII VII v (passing chord)
    chords = {0: [57, 60, 64], -4: [53, 57, 60], -2: [55, 59, 62], -5: [52, 55, 59], -3: [54, 57, 60]}
    patterns = {
        "a": [0, None, 12, 0, 0, 10, None, 12, 0, 0, 7, None, 12, 0, 3, 5],
        "b": [0, 12, None, 0, 7, None, 12, 10, 0, None, 0, 12, 3, None, 7, 12],
    }
    accents = [1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0]
    arp_steps = [12, 15, 19, 24, 19, 15, 12, 7]

    notes, accs = [], []
    for bar in range(bars):
        key, variant = PHASE_SECTIONS[bar // 8]
        local = bar % 8
        r = roots[local] + key
        pattern = patterns["b" if variant in ("lift", "full") and local % 2 == 1 else "a"]
        for i in range(16):
            p = pattern[i]
            notes.append(None if p is None else 33 + r + p)
            accs.append(accents[i])
        t0 = bar * 4 * beat
        quiet_drums = variant == "bridge" and local < 4
        for b in range(4):
            mix_into(base, t0 + b * beat, kick(), 0.55 if quiet_drums else 1.0)
            mix_into(base, t0 + b * beat + beat / 2, hat(True), 0.28)
            if b in (1, 3) and not quiet_drums:
                mix_into(base, t0 + b * beat, clap(), 0.45)
        for i in range(16):
            if i % 2 == 1 or variant == "full":
                mix_into(base, t0 + i * step, hat(), 0.18 if i % 2 == 1 else 0.1)
            mix_into(rush, t0 + i * step, hat(), 0.2 if i % 2 == 0 else 0.0)
        # Rave stabs; the bridge uses longer, higher chords.
        chord = [m + key for m in chords[roots[local]]]
        if variant == "bridge":
            for pos in (0.0, 2.5):
                mix_into(base, t0 + pos * beat, stab([m + 12 for m in chord], 0.6, 3200), 0.3)
        else:
            for pos in (1.5, 3.5) if bar % 2 == 0 else (0.75, 2.5, 3.5):
                mix_into(base, t0 + pos * beat, stab([m + 12 for m in chord]), 0.35)
        # Arp: second half of the intro, whole lift/full, an octave up in the bridge.
        if (variant == "intro" and local >= 4) or variant in ("lift", "full", "bridge"):
            octave = 12 if variant == "bridge" else 0
            for i in range(16):
                mix_into(base, t0 + i * step, pluck(57 + r + octave + arp_steps[i % 8], 0.18), 0.12)
        # Snare fill on the last bar of each section announces the key change.
        if local == 7:
            for i in range(8, 16):
                mix_into(base, t0 + i * step, snare(), 0.1 + 0.25 * (i - 8) / 7)
        # Rush layer: 16th snare roll getting louder through each bar + high arp + siren.
        for i in range(16):
            mix_into(rush, t0 + i * step, snare(), 0.18 + 0.35 * (i / 15))
            mix_into(rush, t0 + i * step, pluck(69 + r + arp_steps[(i * 3) % 8], 0.12, 0.5, 4500), 0.28)
        siren_d = 2 * beat
        vib = note_hz(81 + r) * (1 + 0.02 * np.sin(2 * np.pi * 6 * t(siren_d)))
        siren = lowpass(np.sign(sine(vib, siren_d)), 2400) * env_adsr(siren_d, 0.02, 0.1, 0.6, 0.2)
        mix_into(rush, t0 + (0 if bar % 2 == 0 else 2 * beat), siren, 0.2)
    mix_into(base, 0.0, acid_line(notes, accs, step, total, 8 * 4 * beat), 0.55)
    base = echo(base, 3 * step, 0.18, 2)
    scale = 10 ** (-3 / 20) / max(np.max(np.abs(base)), np.max(np.abs(base + rush)))
    return base * scale, rush * scale


def camp_track():
    bpm = 112
    beat = 60 / bpm
    step = beat / 4
    bars = 16
    total = bars * 4 * beat
    out = np.zeros(int(total * SR))
    progression = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]   # Am F C G
    arps = [[0, 2, 1, 2, 0, 2, 1, 2], [0, 1, 2, 1, 2, 1, 0, 2]]
    for bar in range(bars):
        key = 0 if bar < 8 else 2                      # second half one tone up (Bm G D A)
        chord = [m + key for m in progression[(bar // 2) % 4]]
        arp = arps[bar // 8]
        t0 = bar * 4 * beat
        if bar % 2 == 0:
            mix_into(out, t0, pad(chord, 8 * beat), 0.5)
            mix_into(out, t0, sine(note_hz(chord[0] - 24), 8 * beat) * env_adsr(8 * beat, 0.05, 0.3, 0.7, 0.5), 0.35)
        for b in range(4):
            if b in (0, 2):
                mix_into(out, t0 + b * beat, kick(0.1), 0.35)
            mix_into(out, t0 + b * beat + beat / 2, hat(True), 0.08)
        for i in range(8):
            m = chord[arp[i]] + (12 if bar < 8 else 24)
            mix_into(out, t0 + i * 2 * step, pluck(m, 0.3, 0.5, 2200), 0.16 if bar < 8 else 0.12)
    out = echo(out, 3 * step, 0.3, 3)
    return normalize(out, -4.0)


if __name__ == "__main__":
    base, rush = phase_tracks()
    write_ogg(OUT + "phase_base.ogg", base)
    write_ogg(OUT + "phase_rush.ogg", rush)
    write_ogg(OUT + "camp.ogg", camp_track())
