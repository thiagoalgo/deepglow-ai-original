"""Generates the music loops into assets/audio/music/*.ogg.

- camp: 112 BPM calmer loop (16 bars, second half one tone up) for menus.
- camp_fast / camp_fast_rush: the same loop at CAMP_PHASE_BPM for the phases,
  with a rush layer (16th hats + snare roll) of the same length, played in sync
  (AudioStreamSynchronized) and faded in when the phase timer runs low.
  (A 132 BPM acid techno phase track was replaced: the owner found it bad.)
Every note tail wraps around to the start, so the loops are seamless.
Run from the repo root:  python3 tools/audio/music.py
"""
from synth import *  # noqa: F401,F403

OUT = "assets/audio/music/"
# Tempo of the menu loop when it plays during the phases (menu: 112).
CAMP_PHASE_BPM = 128


# --- Instruments -----------------------------------------------------------------

def kick(gain_click=0.3):
    d = 0.3
    body = sine(sweep(160, 42, d, 0.35), d) * env_exp(d, 0.14, 0.001)
    tick = highpass(noise(0.006), 3000) * gain_click
    return body + np.pad(tick, (0, len(body) - len(tick)))


def hat(open_=False):
    d = 0.2 if open_ else 0.05
    return highpass(noise(d), 6500 if open_ else 8000, 3) * env_exp(d, 0.07 if open_ else 0.012)


def snare():
    d = 0.12
    return bandpass(noise(d), 1200, 6000) * env_exp(d, 0.035) + \
        sine(sweep(260, 180, d), d) * env_exp(d, 0.02) * 0.4


def pluck(midi, d=0.25, duty=0.25, cutoff=3200):
    return lowpass(square(note_hz(midi), d, duty), cutoff) * env_exp(d, 0.06, 0.001)


def pad(midis, d, cutoff=1100):
    x = sum(saw(note_hz(m) * det, d) for m in midis for det in (0.993, 1.0, 1.007))
    return lowpass(x / (3 * len(midis)), cutoff) * env_adsr(d, d * 0.3, 0.1, 0.8, d * 0.3)


def echo(x, delay_s, feedback=0.35, repeats=4):
    out = x.copy()
    for k in range(1, repeats + 1):
        out += np.roll(x, int(k * delay_s * SR)) * feedback ** k
    return out


# --- Tracks --------------------------------------------------------------------------

# Phase track sections (8 bars each): (key shift in semitones, variant).
# A minor -> C minor (lift) -> D minor (bridge) -> back to A minor (full).
def camp_track(bpm=112):
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


def camp_rush(bpm):
    """Rush layer for the fast camp (same length, played in sync): 16th hats and
    a snare roll that grows through every bar, faded in when time runs low."""
    beat = 60 / bpm
    step = beat / 4
    bars = 16
    out = np.zeros(int(bars * 4 * beat * SR))
    for bar in range(bars):
        t0 = bar * 4 * beat
        for i in range(16):
            mix_into(out, t0 + i * step, hat(), 0.14 if i % 2 == 0 else 0.08)
            if i >= 8 or bar % 2 == 1:
                mix_into(out, t0 + i * step, snare(), 0.06 + 0.18 * (i / 15))
        mix_into(out, t0 + beat, kick(0.1), 0.3)
        mix_into(out, t0 + 3 * beat, kick(0.1), 0.3)
    return out


def camp_phase_tracks(bpm=CAMP_PHASE_BPM):
    """The menu loop, faster, for the phases (owner request): base + rush layer."""
    base = camp_track(bpm)
    rush = camp_rush(bpm)[:len(base)]
    scale = 10 ** (-3 / 20) / max(np.max(np.abs(base)), np.max(np.abs(base + rush)))
    return base * scale, rush * scale


if __name__ == "__main__":
    write_ogg(OUT + "camp.ogg", camp_track())
    fast, fast_rush = camp_phase_tracks()
    write_ogg(OUT + "camp_fast.ogg", fast)
    write_ogg(OUT + "camp_fast_rush.ogg", fast_rush)
