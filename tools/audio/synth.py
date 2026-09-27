"""Tiny numpy synth used to generate Deepglow's audio (no samples, no licenses).

All sounds are built from oscillators, noise, envelopes and filters, so they
are fully owned by the project and reproducible: edit the recipe, re-run the
script, commit the .ogg. Mono, 44.1 kHz.
"""
from __future__ import annotations

import os
import subprocess
import tempfile

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, lfilter

SR = 44100
RNG = np.random.default_rng(7)


def t(seconds: float) -> np.ndarray:
    return np.arange(int(seconds * SR)) / SR


def note_hz(midi: float) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12)


# --- Oscillators ---------------------------------------------------------------

def sine(freq, seconds: float, phase: float = 0.0) -> np.ndarray:
    tt = t(seconds)
    if np.ndim(freq) == 0:
        return np.sin(2 * np.pi * freq * tt + phase)
    return np.sin(2 * np.pi * np.cumsum(freq) / SR + phase)


def square(freq: float, seconds: float, duty: float = 0.5) -> np.ndarray:
    return np.where((t(seconds) * freq) % 1.0 < duty, 1.0, -1.0)


def saw(freq: float, seconds: float) -> np.ndarray:
    return 2.0 * ((t(seconds) * freq) % 1.0) - 1.0


def noise(seconds: float) -> np.ndarray:
    return RNG.uniform(-1.0, 1.0, int(seconds * SR))


def sweep(f0: float, f1: float, seconds: float, curve: float = 1.0) -> np.ndarray:
    """Frequency array going from f0 to f1 (for sine())."""
    x = np.linspace(0.0, 1.0, int(seconds * SR)) ** curve
    return f0 + (f1 - f0) * x


# --- Envelopes / filters -------------------------------------------------------

def env_exp(seconds: float, decay: float, attack: float = 0.002) -> np.ndarray:
    tt = t(seconds)
    e = np.exp(-tt / max(decay, 1e-4))
    a = int(attack * SR)
    if a > 0:
        e[:a] *= np.linspace(0.0, 1.0, a)
    return e


def env_adsr(seconds: float, a: float, d: float, s: float, r: float) -> np.ndarray:
    n = int(seconds * SR)
    e = np.full(n, s)
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    e[:na] = np.linspace(0, 1, na) if na else e[:na]
    e[na:na + nd] = np.linspace(1, s, len(e[na:na + nd]))
    if nr:
        e[-nr:] *= np.linspace(1, 0, len(e[-nr:]))
    return e


def lowpass(x: np.ndarray, cutoff: float, order: int = 2) -> np.ndarray:
    b, a = butter(order, min(cutoff, SR / 2 - 100) / (SR / 2), "low")
    return lfilter(b, a, x)


def highpass(x: np.ndarray, cutoff: float, order: int = 2) -> np.ndarray:
    b, a = butter(order, cutoff / (SR / 2), "high")
    return lfilter(b, a, x)


def bandpass(x: np.ndarray, lo: float, hi: float, order: int = 2) -> np.ndarray:
    b, a = butter(order, [lo / (SR / 2), hi / (SR / 2)], "band")
    return lfilter(b, a, x)


def resonant_lowpass(x: np.ndarray, cutoff: np.ndarray, resonance: float = 0.8) -> np.ndarray:
    """State-variable filter with a per-sample cutoff (acid bass)."""
    out = np.zeros_like(x)
    low = band = 0.0
    q = 1.0 - resonance * 0.95
    for i in range(len(x)):
        f = 2.0 * np.sin(np.pi * min(cutoff[i], SR / 6) / SR)
        low += f * band
        high = x[i] - low - q * band
        band += f * high
        out[i] = low
    return out


# --- Mixing ------------------------------------------------------------------------

def mix_into(buffer: np.ndarray, start_s: float, signal: np.ndarray, gain: float = 1.0,
             wrap: bool = True) -> None:
    """Adds `signal` at `start_s`; with wrap=True tails continue from the start (loops)."""
    start = int(round(start_s * SR))
    n = len(buffer)
    for offset in range(0, len(signal), n):
        chunk = signal[offset:offset + n] * gain
        idx = (np.arange(len(chunk)) + start + offset) % n if wrap else None
        if wrap:
            np.add.at(buffer, idx, chunk)
        else:
            end = min(n, start + len(chunk))
            buffer[start:end] += chunk[:end - start]
            break


def normalize(x: np.ndarray, peak_db: float = -1.0) -> np.ndarray:
    peak = np.max(np.abs(x)) or 1.0
    return x / peak * 10 ** (peak_db / 20)


def fade_edges(x: np.ndarray, ms: float = 3.0) -> np.ndarray:
    n = int(ms / 1000 * SR)
    x = x.copy()
    x[:n] *= np.linspace(0, 1, n)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def soft_clip(x: np.ndarray, drive: float = 1.0) -> np.ndarray:
    return np.tanh(x * drive) / np.tanh(drive)


def write_ogg(path: str, x: np.ndarray, quality: int = 5) -> None:
    """Writes mono float audio as Ogg Vorbis (via ffmpeg)."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pcm = (np.clip(x, -1.0, 1.0) * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wavfile.write(tmp.name, SR, pcm)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name,
                    "-c:a", "libvorbis", "-q:a", str(quality), path], check=True)
    os.unlink(tmp.name)
    print(f"wrote {path} ({len(x) / SR:.2f}s)")
