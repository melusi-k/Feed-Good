#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON_DIR="$ROOT/FeedGood/Assets.xcassets/AppIcon.appiconset"
SOURCE="$ICON_DIR/FeedGood-AppIcon.svg"
OUTPUT="$ICON_DIR/FeedGood-AppIcon.png"

python3 -m pip install --quiet --disable-pip-version-check CairoSVG
python3 - "$SOURCE" "$OUTPUT" <<'PY'
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
