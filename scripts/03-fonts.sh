#!/usr/bin/env bash
# 3. Fonts for map labels. Martin turns these into the glyph files MapLibre asks for.
. "$(dirname "$0")/common.sh"
need curl "Install it with: sudo apt install curl"
mkdir -p data/fonts
base=https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSans/full/ttf
for f in NotoSans-Regular NotoSans-Bold; do
  curl -L --fail -o "data/fonts/$f.ttf" "$base/$f.ttf"
done
ls data/fonts
