#!/usr/bin/env python3
"""Prepare narration recordings for the game (intro and ending voice lines).

Takes the MP3/WAV files exported from the voice tool (ElevenLabs, paid plan =
commercial license), named `<id>_NN_<locale>.mp3` (intro, ending), and writes
`assets/audio/voice/<locale>/<id>_NN.ogg`:
  - leading/trailing silence trimmed (below -50 dB),
  - loudness normalized to -16 LUFS, true peak -1.5 dB (all lines equally loud;
    two passes: measure, then a plain gain + limiter — the one-pass dynamic
    loudnorm leaves lines shorter than 3 s far too quiet),
  - mono, 44.1 kHz, Ogg Vorbis q5.

Usage: python3 tools/audio/voice.py <source_dir> [glob]
       (default source: $DEEPGLOW_ART_DIR/06_voice; glob limits the files, e.g. 'ending_07_*')
Needs ffmpeg.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets' / 'audio' / 'voice'
NAME = re.compile(r'^(?P<id>[a-z_]+_\d+)_(?P<locale>[a-z]{2}(?:_[A-Z]{2})?)\.(mp3|wav|ogg)$')
TRIM = ('silenceremove=start_periods=1:start_threshold=-50dB,'
        'areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse')
LOUDNORM = 'loudnorm=I=-16:TP=-1.5:LRA=11'
TARGET_LUFS = -16.0
LIMIT = 10 ** (-1.5 / 20)  # -1.5 dBFS


def measure(path: Path) -> dict[str, str]:
    """First loudnorm pass: the line's loudness after trimming."""
    result = subprocess.run(['ffmpeg', '-hide_banner', '-i', str(path), '-af',
                             f'{TRIM},{LOUDNORM}:print_format=json', '-f', 'null', '-'],
                            capture_output=True, text=True, check=True)
    return json.loads(result.stderr[result.stderr.rindex('{'):])


def normalize_filter(stats: dict[str, str]) -> str:
    """Second pass: a plain gain to -16 LUFS + a limiter at -1.5 dB (loudnorm's own
    linear mode misbehaves on short lines in older ffmpeg builds)."""
    gain = TARGET_LUFS - float(stats['input_i'])
    return f"{TRIM},volume={gain:.2f}dB,alimiter=limit={LIMIT:.3f}:level=disabled"


def main() -> None:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(os.environ.get('DEEPGLOW_ART_DIR', '.')) / '06_voice'
    pattern = sys.argv[2] if len(sys.argv) > 2 else '*'
    for path in sorted(src.glob(pattern)):
        match = NAME.match(path.name)
        if not match:
            continue
        out = OUT / match['locale'] / f"{match['id']}.ogg"
        out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(path), '-af', normalize_filter(measure(path)),
                        '-ac', '1', '-ar', '44100', '-c:a', 'libvorbis', '-q:a', '5', str(out)], check=True)
        print(out.relative_to(ROOT))


if __name__ == '__main__':
    main()
