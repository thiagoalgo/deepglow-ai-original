#!/usr/bin/env python3
"""Minimal Pixellab REST API v2 client for Deepglow (stdlib only).

Configuration (.env at the Godot project root, NEVER committed):
  PIXELLAB_API_KEY=...                  # https://pixellab.ai/account
  DEEPGLOW_ART_DIR=/Users/thiago/Documents/gamedev/deepglow/pixelart

Commands:
  balance                               account balance
  image  "description" [--size 32] [--width W --height H] [--bg] [--name slug]
                                        generate a pixflux image (transparent by default)
  call   ENDPOINT --body JSON|@file.json [--name slug]
                                        call any v2 POST endpoint and save every
                                        base64 image in the response
  job    JOB_ID [--name slug]           poll a background job and save its result
  character-zip CHARACTER_ID [--name slug]
                                        download a character ZIP (rotations + animations)
  spritesheet CHARACTER_ID [--name slug]
                                        download a character spritesheet ZIP (png + json)

Everything is saved to $DEEPGLOW_ART_DIR/03_pixellab/YYYY-MM-DD/<slug>/ with a
request.json (prompt/parameters) and response.json (base64 stripped) for
reproducibility. Use --out for another destination.
Docs: https://api.pixellab.ai/v2/llms.txt  |  OpenAPI: https://api.pixellab.ai/v2/openapi.json
"""
from __future__ import annotations

import argparse
import base64
import datetime as dt
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.pixellab.ai/v2"
ROOT = Path(__file__).resolve().parents[2]
POLL_INTERVAL = 5
POLL_TIMEOUT = 15 * 60


# --- configuration ------------------------------------------------------------

def load_env() -> None:
    env = ROOT / ".env"
    if not env.exists():
        return
    for line in env.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


def api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY", "")
    if not key:
        sys.exit("PIXELLAB_API_KEY is not set (create .env from .env.example).")
    return key


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")[:48] or "asset"


def out_dir(args, fallback_name: str) -> Path:
    if args.out:
        d = Path(args.out).expanduser()
    else:
        base = Path(os.environ.get("DEEPGLOW_ART_DIR", ROOT / "_pixellab_out")).expanduser()
        vm_mount = Path.home() / "mnt" / "pixelart"  # mounted folder when running through Claude/Cowork
        if not base.exists() and vm_mount.exists():
            base = vm_mount
        d = base / "03_pixellab" / dt.date.today().isoformat() / slugify(args.name or fallback_name)
    return d


# --- HTTP --------------------------------------------------------------------

def request(method: str, path: str, body: dict | None = None, raw: bool = False):
    url = path if path.startswith("http") else f"{API}/{path.lstrip('/')}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {api_key()}")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            payload = resp.read()
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code} em {method} {url}:\n{e.read().decode(errors='replace')}")
    except urllib.error.URLError as e:
        sys.exit(f"Network error on {url}: {e.reason}\n"
                 "When running through Claude/Cowork, the api.pixellab.ai domain must be "
                 "allowed in the network settings.")
    return payload if raw else json.loads(payload or b"{}")


# --- image extraction ---------------------------------------------------------

def _decode_b64(value: str) -> bytes | None:
    if value.startswith("data:image"):
        value = value.split(",", 1)[1]
    try:
        blob = base64.b64decode(value, validate=True)
    except Exception:
        return None
    return blob if blob[:8] == b"\x89PNG\r\n\x1a\n" else None


def extract_images(obj, path: str = "") -> tuple[list[tuple[str, bytes]], object]:
    """Walk the response; return [(path, png_bytes)] and a copy without base64."""
    found: list[tuple[str, bytes]] = []

    def walk(node, p):
        if isinstance(node, dict):
            if isinstance(node.get("base64"), str):
                blob = _decode_b64(node["base64"])
                if blob:
                    found.append((p or "image", blob))
                    return {**node, "base64": f"<{len(blob)} bytes saved>"}
            return {k: walk(v, f"{p}.{k}" if p else k) for k, v in node.items()}
        if isinstance(node, list):
            return [walk(v, f"{p}_{i}") for i, v in enumerate(node)]
        if isinstance(node, str) and len(node) > 200:
            blob = _decode_b64(node)
            if blob:
                found.append((p or "image", blob))
                return f"<{len(blob)} bytes saved>"
        return node

    stripped = walk(obj, path)
    return found, stripped


def save_result(dest: Path, response, request_body: dict | None = None, endpoint: str = "") -> None:
    dest.mkdir(parents=True, exist_ok=True)  # only create the folder after a valid response
    images, stripped = extract_images(response)
    for key, blob in images:
        name = slugify(key.replace(".", "_")) + ".png"
        (dest / name).write_bytes(blob)
        print(f"  image: {dest / name}")
    if request_body is not None:
        meta = {"endpoint": endpoint, "timestamp": dt.datetime.now().isoformat(), "body": request_body}
        (dest / "request.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False))
    (dest / "response.json").write_text(json.dumps(stripped, indent=2, ensure_ascii=False))
    if not images:
        print("  (no image in the response — see response.json)")


def job_id_of(resp) -> str | None:
    if isinstance(resp, dict):
        return resp.get("background_job_id") or resp.get("job_id")
    return None


def poll_job(job_id: str) -> dict:
    start = time.time()
    while True:
        job = request("GET", f"background-jobs/{job_id}")
        status = job.get("status")
        if status not in ("processing", "pending", "queued"):
            return job
        if time.time() - start > POLL_TIMEOUT:
            sys.exit(f"Timeout aguardando job {job_id}")
        print(f"  job {job_id}: {status}...", flush=True)
        time.sleep(POLL_INTERVAL)


# --- comandos ----------------------------------------------------------------

def cmd_balance(args) -> None:
    print(json.dumps(request("GET", "balance"), indent=2))


def run_post(args, endpoint: str, body: dict, fallback_name: str) -> None:
    dest = out_dir(args, fallback_name)
    print(f"POST /{endpoint} -> {dest}")
    resp = request("POST", endpoint, body)
    save_result(dest, resp, body, endpoint)
    jobs = []
    if job_id_of(resp):
        jobs.append(job_id_of(resp))
    if isinstance(resp, dict) and isinstance(resp.get("background_job_ids"), list):
        jobs.extend(resp["background_job_ids"])
    for i, jid in enumerate(jobs):
        job = poll_job(jid)
        sub = dest / f"job_{i}" if len(jobs) > 1 else dest
        sub.mkdir(exist_ok=True)
        print(f"  job {jid}: {job.get('status')}")
        save_result(sub, job)


def cmd_image(args) -> None:
    w = args.width or args.size
    h = args.height or args.size
    body = {
        "description": args.description,
        "image_size": {"width": w, "height": h},
        "no_background": not args.bg,
    }
    run_post(args, "create-image-pixflux", body, args.description)


def cmd_call(args) -> None:
    raw = args.body
    body = json.loads(Path(raw[1:]).read_text() if raw.startswith("@") else raw)
    run_post(args, args.endpoint.strip("/"), body, args.endpoint)


def cmd_job(args) -> None:
    dest = out_dir(args, f"job_{args.job_id[:8]}")
    save_result(dest, poll_job(args.job_id))


def _download(args, kind: str) -> None:
    dest = out_dir(args, f"character_{args.character_id[:8]}")
    blob = request("GET", f"characters/{args.character_id}/{kind}", raw=True)
    f = dest / f"{kind}.zip"
    f.write_bytes(blob)
    print(f"  saved: {f}")


def main() -> None:
    load_env()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    def common(p):
        p.add_argument("--name", help="output folder slug")
        p.add_argument("--out", help="explicit output folder")
        return p

    sub.add_parser("balance").set_defaults(func=cmd_balance)

    p = common(sub.add_parser("image"))
    p.add_argument("description")
    p.add_argument("--size", type=int, default=32, help="side (px) when width/height are omitted; API minimum is 32")
    p.add_argument("--width", type=int)
    p.add_argument("--height", type=int)
    p.add_argument("--bg", action="store_true", help="keep background (default: transparent)")
    p.set_defaults(func=cmd_image)

    p = common(sub.add_parser("call"))
    p.add_argument("endpoint")
    p.add_argument("--body", required=True, help="JSON inline ou @arquivo.json")
    p.set_defaults(func=cmd_call)

    p = common(sub.add_parser("job"))
    p.add_argument("job_id")
    p.set_defaults(func=cmd_job)

    p = common(sub.add_parser("character-zip"))
    p.add_argument("character_id")
    p.set_defaults(func=lambda a: _download(a, "zip"))

    p = common(sub.add_parser("spritesheet"))
    p.add_argument("character_id")
    p.set_defaults(func=lambda a: _download(a, "spritesheet"))

    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
