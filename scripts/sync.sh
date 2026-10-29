#!/usr/bin/env bash
# Capture live config from this machine INTO the repo. Inverse of deploy.sh.
# The app list below is an allowlist on purpose: syncing all of ~/.config would
# reach browser profiles (cookies, history, password stores).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
case "${1:-}" in
  -n|--dry-run) DRY_RUN=1 ;;
  "") ;;
  *) echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

# link: deploy.sh symlinks these, so the repo copy must mirror the live dir exactly.
LINK_APPS=(i3 polybar picom rofi dunst kitty fontconfig gtk-3.0 xsettingsd nvim lazygit zellij)
# copy: these tools rewrite their own config dir, so only our files are captured,
# and the repo never becomes a symlink they could pollute.
COPY_APPS=("btop:btop.conf" "opencode:opencode.jsonc" "kilo:kilo.jsonc")
CONFIG_FILES=(mimeapps.list spectaclerc)
HOME_FILES=(.zshrc .zshenv .gitconfig)

RSYNC_EXCLUDES=(
  --exclude '.git/'
  --exclude '*.bak'
  --exclude '*.bak.*'
  --exclude '*~'
  --exclude '*.swp'
  --exclude 'node_modules/'
  --exclude 'cache/'
  --exclude 'Cache/'
  --exclude '*.log'
)

SECRET_RE='cookies|sessionstore|places\.sqlite|logins\.json|key[0-9]*\.db|pkcs11\.txt|credentials|\.pem$|\.key$|\.env$|token'

c_red=$'\033[0;31m'; c_grn=$'\033[0;32m'; c_yel=$'\033[1;33m'; c_off=$'\033[0m'
if [ ! -t 1 ]; then c_red=""; c_grn=""; c_yel=""; c_off=""; fi

die() { echo "${c_red}ERROR:${c_off} $*" >&2; exit 1; }
note() { echo "${c_yel}>>${c_off} $*"; }
ok() { echo "${c_grn}✓${c_off} $*"; }

do_cp() {
  local src="$1" dst="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    (dry) cp -a $src $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
  fi
}

abort_on_secrets() {
  local src="$1" hits
  hits="$(find "$src" -type f \( -regextype posix-extended -regex ".*($SECRET_RE)" \) 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    die "refusing to capture $src, it contains files that look secret-shaped:
$hits"
  fi
}

require_under_home() {
  local resolved
  resolved="$(readlink -f "$1")"
  case "$resolved" in
    "$HOME"/*) : ;;
    *) die "$1 resolves outside \$HOME ($resolved); refusing" ;;
  esac
}

already_linked() {
  local target="$1" item="$2"
  [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$item")" ]
}

RSYNC_FLAGS=(-a)
if [ "$DRY_RUN" -eq 1 ]; then
  RSYNC_FLAGS+=(-n)
  note "dry run: nothing will be written"
fi

for app in "${LINK_APPS[@]}"; do
  src="$HOME/.config/$app"
  dst="$REPO/.config/$app"
  if [ ! -e "$src" ]; then
    note "skipping $app: not present on this machine"
    continue
  fi
  require_under_home "$src"
  if already_linked "$src" "$dst"; then
    ok "$app: repo copy is already live, nothing to capture"
    continue
  fi
  abort_on_secrets "$src"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$dst"
  fi
  rsync "${RSYNC_FLAGS[@]}" --delete "${RSYNC_EXCLUDES[@]}" "$src/" "$dst/"
  ok "captured ~/.config/$app"
done

for entry in "${COPY_APPS[@]}"; do
  app="${entry%%:*}"
  file="${entry#*:}"
  src="$HOME/.config/$app/$file"
  if [ ! -f "$src" ]; then
    note "skipping $app/$file: not present"
    continue
  fi
  require_under_home "$src"
  do_cp "$src" "$REPO/.config/$app/$file"
  ok "captured ~/.config/$app/$file (copy-mode: other files in that dir stay local)"
done

for file in "${CONFIG_FILES[@]}"; do
  src="$HOME/.config/$file"
  if [ ! -f "$src" ]; then
    note "skipping ~/.config/$file: not present"
    continue
  fi
  require_under_home "$src"
  do_cp "$src" "$REPO/.config/$file"
  ok "captured ~/.config/$file"
done

for file in "${HOME_FILES[@]}"; do
  src="$HOME/$file"
  if [ ! -f "$src" ]; then
    note "skipping ~/$file: not present"
    continue
  fi
  do_cp "$src" "$REPO/home/$file"
  ok "captured ~/$file"
done

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete. Re-run without --dry-run to write, then review with:"
  echo "  git -C $REPO status --short && git -C $REPO diff"
else
  echo "Capture complete. Review before committing:"
  echo "  git -C $REPO status --short"
fi
