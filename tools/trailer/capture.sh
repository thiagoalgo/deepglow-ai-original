#!/bin/bash
# Records real gameplay for the trailer with Godot's Movie Maker (1920x1080, 30 fps).
# Works on a copy of the project, so project.godot is never changed.
# Usage: GODOT=/path/to/godot tools/trailer/capture.sh <name> <save NN> <seconds> [key=value ...]
#   keys (read by src/dev/trailer_director.gd): buys=N cps=N tree_scroll=N summary_hold=S music=1 lang=pt_BR
# Linux without a display: prefix with  xvfb-run -a -s "-screen 0 1920x1080x24"
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${CAPTURE_DIR:-$ROOT/build/trailer_capture}"
GODOT="${GODOT:?set GODOT to the Godot 4.7 binary}"
NAME=$1; SAVE=$2; SECS=$3; shift 3
WORK="$(mktemp -d)"
mkdir -p "$OUT"
rsync -a --exclude .git --exclude .godot --exclude build --exclude 'Claude outputs' "$ROOT/" "$WORK/"
perl -pi -e 's/window_width_override=.*/window_width_override=1920/; s/window_height_override=.*/window_height_override=1080/; s#^(Platform="\*res://src/autoload/platform.gd")$#$1\nTrailerDirector="*res://src/dev/trailer_director.gd"#' "$WORK/project.godot"
"$GODOT" --headless --path "$WORK" --import > /dev/null 2>&1 || true
# The director loads the test save over the save slot: back up your own save first if it matters.
"$GODOT" --path "$WORK" --write-movie "$OUT/$NAME.avi" --fixed-fps 30 -- save=$SAVE seconds=$SECS "$@"
ffmpeg -v error -y -i "$OUT/$NAME.avi" -c:v libx264 -crf 12 -preset veryfast -pix_fmt yuv420p -c:a aac -b:a 256k "$OUT/$NAME.mp4"
rm "$OUT/$NAME.avi"
rm -rf "$WORK"
echo "Saved $OUT/$NAME.mp4"
