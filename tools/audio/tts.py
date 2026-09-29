#!/usr/bin/env python3
"""Generate narration lines with the ElevenLabs text-to-speech API.

Reads the lines from localization/translations.csv by key prefix (e.g.
ENDING_ -> ENDING_01..NN) and writes one MP3 per line and locale to
`$DEEPGLOW_ART_DIR/06_voice/<id>_NN_<locale>.mp3` (the input of voice.py).
Existing files are kept unless --force (credits are limited).

Voices (AGENTS.md §5.1): en = Connery, pt_BR = Lucas; model eleven_multilingual_v2.
The API key comes from ELEVENLABS_API_KEY (environment or the repo .env; never commit it).

Usage: python3 tools/audio/tts.py ENDING [--locales en,pt_BR] [--force] [--out DIR]
Then:  python3 tools/audio/voice.py $DEEPGLOW_ART_DIR/06_voice
Stdlib only.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CSV = ROOT / 'localization' / 'translations.csv'
MODEL = 'eleven_multilingual_v2'
VOICES = {
    'en': 'onwK4e9ZLuTAKqWW03F9',     # Connery
    'pt_BR': 'GIuLCSVfgJaUuh7hYOY8',  # Lucas
}
URL = 'https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128'


def api_key() -> str:
    key = os.environ.get('ELEVENLABS_API_KEY', '')
    env = ROOT / '.env'
    if not key and env.exists():
        for line in env.read_text().splitlines():
            name, _, value = line.partition('=')
            if name.strip().removeprefix('export ').strip() == 'ELEVENLABS_API_KEY':
                key = value.strip().strip('"\'')
    if not key:
        sys.exit('ELEVENLABS_API_KEY not set (environment or .env)')
    return key


def lines(prefix: str) -> list[dict[str, str]]:
    with CSV.open(encoding='utf-8') as f:
        rows = [row for row in csv.DictReader(f) if row['keys'].startswith(prefix + '_')]
    if not rows:
        sys.exit(f'no keys starting with {prefix}_ in {CSV}')
    return sorted(rows, key=lambda row: row['keys'])


def speak(key: str, voice: str, text: str) -> bytes:
    body = json.dumps({'text': text, 'model_id': MODEL}).encode()
    request = urllib.request.Request(URL.format(voice=voice), data=body, method='POST', headers={
        'xi-api-key': key, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'})
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        sys.exit(f'ElevenLabs error {error.code}: {error.read().decode(errors="replace")[:300]}')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('prefix', help='translation key prefix, e.g. ENDING')
    parser.add_argument('--locales', default=','.join(VOICES))
    parser.add_argument('--force', action='store_true', help='regenerate existing files')
    parser.add_argument('--out', type=Path,
        default=Path(os.environ.get('DEEPGLOW_ART_DIR', '.')) / '06_voice')
    args = parser.parse_args()
    key = api_key()
    args.out.mkdir(parents=True, exist_ok=True)
    for row in lines(args.prefix):
        number = row['keys'].rsplit('_', 1)[1]
        for locale in args.locales.split(','):
            out = args.out / f'{args.prefix.lower()}_{number}_{locale}.mp3'
            if out.exists() and not args.force:
                print(f'skip {out.name}')
                continue
            out.write_bytes(speak(key, VOICES[locale], row[locale]))
            print(out)


if __name__ == '__main__':
    main()
