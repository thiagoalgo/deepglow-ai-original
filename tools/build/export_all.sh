#!/usr/bin/env bash
# Exports release builds for every preset in export_presets.cfg into build/.
# Needs the Godot export templates for the editor version
# (Editor > Manage Export Templates > Download and Install).
#
#   GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/build/export_all.sh
#   tools/build/export_all.sh Linux          # a single preset
#   tools/build/export_all.sh "Web (demo)"   # itch.io demo (needs the Web export templates)
set -euo pipefail
cd "$(dirname "$0")/../.."

GODOT="${GODOT:-godot}"
VERSION=$(sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)
if [ $# -gt 0 ]; then PRESETS=("$@"); else PRESETS=(Windows macOS Linux); fi

"$GODOT" --headless --path . --import
for preset in "${PRESETS[@]}"; do
	path=$(awk -v name="$preset" '
		/^\[preset\.[0-9]+\]$/ { in_preset = 1; found = 0; next }
		/^\[/ { in_preset = 0 }
		in_preset && $0 == "name=\"" name "\"" { found = 1 }
		in_preset && found && /^export_path=/ { gsub(/^export_path="|"$/, ""); print; exit }
	' export_presets.cfg)
	mkdir -p "$(dirname "$path")"
	echo "== $preset -> $path (v$VERSION)"
	"$GODOT" --headless --path . --export-release "$preset" "$path"
done
echo "Done. Builds in build/ (git-ignored)."
