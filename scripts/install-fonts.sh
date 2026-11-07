#!/usr/bin/env bash
# Install the JetBrainsMono Nerd Font variant polybar, rofi, ghostty and
# xsettingsd all name explicitly.
#
# Fedora's jetbrains-mono-fonts package has NO Nerd glyphs, so without this the
# bar renders tofu boxes instead of icons. The upstream zip is ~130MB and holds
# every weight/width; only the 8 faces actually referenced are kept.
set -euo pipefail

ZIP_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
DEST="$HOME/.local/share/fonts/JetBrainsMono"
FORCE=0
if [ "${1:-}" = "--force" ]; then
  FORCE=1
fi

FACES=(
  JetBrainsMonoNerdFont-Regular.ttf
  JetBrainsMonoNerdFont-Bold.ttf
  JetBrainsMonoNerdFont-Italic.ttf
  JetBrainsMonoNerdFont-BoldItalic.ttf
  JetBrainsMonoNerdFontMono-Regular.ttf
  JetBrainsMonoNerdFontMono-Bold.ttf
  JetBrainsMonoNerdFontMono-Italic.ttf
  JetBrainsMonoNerdFontMono-BoldItalic.ttf
)

probe() { fc-match -f '%{family}\n' "JetBrainsMono Nerd Font" 2>/dev/null || echo ""; }
fallback() { fc-match -f '%{family}\n' "ThisFontDoesNotExistAtAll" 2>/dev/null || echo ""; }

if [ "$FORCE" -eq 0 ] && [ -n "$(probe)" ] && [ "$(probe)" != "$(fallback)" ]; then
  echo "✓ JetBrainsMono Nerd Font already installed and matching; nothing to do."
  echo "  (fc-match: $(probe))"
  exit 0
fi

command -v curl >/dev/null || { echo "ERROR: curl is required." >&2; exit 1; }
command -v unzip >/dev/null || { echo "ERROR: unzip is required (dnf install unzip)." >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "==> Downloading $ZIP_URL (~130MB, contains every weight; only 8 faces are kept)"
curl -fL --retry 3 -sS -o "$tmp/JetBrainsMono.zip" "$ZIP_URL"

echo "==> Extracting ${#FACES[@]} faces"
unzip -q -o "$tmp/JetBrainsMono.zip" -d "$tmp"
mkdir -p "$DEST"
missing=0
for face in "${FACES[@]}"; do
  src="$(find "$tmp" -name "$face" -type f | head -1)"
  if [ -z "$src" ]; then
    echo "    !! $face not found in the zip" >&2
    missing=$((missing + 1))
    continue
  fi
  cp "$src" "$DEST/$face"
done
if [ "$missing" -ne 0 ]; then
  echo "ERROR: $missing expected face(s) missing from the release zip; upstream layout changed." >&2
  exit 1
fi

echo "==> Refreshing font cache"
fc-cache -f "$DEST" >/dev/null

matched="$(probe)"
if [ -z "$matched" ] || [ "$matched" = "$(fallback)" ]; then
  echo "ERROR: fontconfig still resolves 'JetBrainsMono Nerd Font' to '$matched'." >&2
  echo "       Polybar/rofi/ghostty would show tofu. Investigate before deploying." >&2
  exit 1
fi

echo "✓ JetBrainsMono Nerd Font installed in $DEST (fc-match: $matched)."
