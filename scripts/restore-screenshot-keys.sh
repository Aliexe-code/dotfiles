#!/usr/bin/env bash
# Re-apply screenshot key settings (idempotent).
# - i3: ensures Print/Shift+Print/Mod+Print bindings exist, reloads i3
# - Plasma/KDE: ensures kglobalshortcutsrc spectacle block binds Print to region
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
I3_CONFIG="$HOME/.config/i3/config"
DOTFILES_I3="$DOTFILES_DIR/.config/i3/config"
SNIPPET="$DOTFILES_DIR/.config/spectacle/kglobalshortcuts-spectacle-snippet.ini"
KGLOBAL="$HOME/.config/kglobalshortcutsrc"

echo "==> i3 bindings"
if grep -q "bindsym Print exec spectacle -r" "$I3_CONFIG" 2>/dev/null; then
  echo "    ✓ Print -> spectacle -r already present"
else
  echo "    + adding spectacle bindings to $I3_CONFIG"
  cp "$I3_CONFIG" "$I3_CONFIG.bak.$(date +%Y%m%d_%H%M%S)"
  cat >> "$I3_CONFIG" <<'EOF'

# Screenshots — Spectacle (Print = select region, GUI kept)
bindsym Print exec spectacle -r
bindsym Shift+Print exec spectacle -f
bindsym $mod+Print exec spectacle -a
EOF
fi
i3 -C -c "$I3_CONFIG" && echo "    ✓ i3 config valid"
i3-msg reload >/dev/null && echo "    ✓ i3 reloaded"

echo "==> KDE/Plasma shortcuts (only matters in Plasma sessions)"
if [ -f "$KGLOBAL" ]; then
  python3 - "$KGLOBAL" "$SNIPPET" <<'EOF'
import sys, re
path, snippet = sys.argv[1], sys.argv[2]
raw = open(snippet).read()
# Only the INI section itself (from its header onwards), never the comments
i = raw.find("[services]")
block = (raw[i:] if i != -1 else raw).strip() + "\n"
text = open(path).read()
pattern = re.compile(r"\[services\]\[org\.kde\.spectacle\.desktop\].*?(?=\n\[|\Z)", re.S)
if pattern.search(text):
    text = pattern.sub(block.rstrip("\n"), text)
else:
    text = text.rstrip("\n") + "\n\n" + block
open(path, "w").write(text)
print("    ✓ spectacle block applied to kglobalshortcutsrc")
EOF
else
  echo "    (skip: $KGLOBAL not present)"
fi

echo "==> verify"
grep -h "spectacle -r" "$I3_CONFIG"
grep -A2 "RectangularRegionScreenShot" "$KGLOBAL" 2>/dev/null | head -n 3 || true
echo "Done. Press Print to test."
