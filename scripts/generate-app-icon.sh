#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON_DIR="$ROOT/FeedGood/Assets.xcassets/AppIcon.appiconset"
SOURCE="$ICON_DIR/FeedGood-AppIcon.svg"
OUTPUT="$ICON_DIR/FeedGood-AppIcon.png"

# Keep Python dependencies isolated from Homebrew's externally managed Python.
VENV_DIR="$(mktemp -d "${TMPDIR:-/tmp}/feed-good-icon.XXXXXX")"
trap 'rm -rf "$VENV_DIR"' EXIT

python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --quiet --disable-pip-version-check "CairoSVG==2.7.1"
"$VENV_DIR/bin/python" - "$SOURCE" "$OUTPUT" <<'PY'
import sys
import cairosvg

cairosvg.svg2png(
    url=sys.argv[1],
    write_to=sys.argv[2],
    output_width=1024,
    output_height=1024,
)
PY

file "$OUTPUT"
