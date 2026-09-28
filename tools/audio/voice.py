#!/usr/bin/env python3
"""Prepare narration recordings for the game (intro voice lines).

Takes the MP3/WAV files exported from the voice tool (ElevenLabs, paid plan =
commercial license), named `intro_NN_<locale>.mp3`, and writes
`assets/audio/voice/<locale>/intro_NN.ogg`:
  - leading/trailing silence trimmed (below -50 dB),
  - loudness normalized to -16 LUFS, true peak -1.5 dB (all lines equally loud),
  - mono, 44.1 kHz, Ogg Vorbis q5.

Usage: python3 tools/audio/voice.py <source_dir>
       (default source: $DEEPGLOW_ART_DIR/06_voice)
Needs ffmpeg.
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets' / 'audio' / 'voice'
NAME = re.compile(r'^(?P<id>[a-z]+_\d+)_(?P<locale>[a-z]{2}(?:_[A-Z]{2})?)\.(mp3|wav|ogg)$')
FILTER = ('silenceremove=start_periods=1:start_threshold=-50dB,'
          'areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse,'
          'loudnorm=I=-16:TP=-1.5:LRA=11')


def main() -> None:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(os.environ.get('DEEPGLOW_ART_DIR', '.')) / '06_voice'
    for path in sorted(src.iterdir()):
        match = NAME.match(path.name)
        if not match:
            continue
        out = OUT / match['locale'] / f"{match['id']}.ogg"
        out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(path), '-af', FILTER,
                        '-ac', '1', '-ar', '44100', '-c:a', 'libvorbis', '-q:a', '5', str(out)], check=True)
        print(out.relative_to(ROOT))


if __name__ == '__main__':
    main()
