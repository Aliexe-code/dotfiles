#!/usr/bin/env bash
# Put this repo's config onto the machine. Read scripts/manifest first:
# link-mode entries become symlinks (so future edits are tracked for free),
# copy-mode entries are files the app itself rewrites.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./manifest
source "$DOTFILES_DIR/scripts/manifest"

BACKUP_DIR="$HOME/.config_backup_$(date +'%Y%m%d_%H%M%S')"
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
if [ ! -t 1 ]; then GREEN=""; BLUE=""; YELLOW=""; NC=""; fi

do_it() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    (dry) $*"
    return 0
  fi
  "$@"
}

stash() {
  # Keep whatever was there before; never silently discard a user's file.
  local target="$1"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$BACKUP_DIR"
  fi
  echo "    ${YELLOW}📦${NC} Backing up existing $target -> $BACKUP_DIR/"
  do_it mv "$target" "$BACKUP_DIR/"
}

is_linked_to() { [ -L "$1" ] && [ "$(readlink -f "$1")" = "$(readlink -f "$2")" ]; }

link_path() {
  local item="$1" target="$2" label="$3"
  if is_linked_to "$target" "$item"; then
    echo "    ${GREEN}✓${NC} $label already linked."
    return 0
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    stash "$target"
  fi
  echo "    ${BLUE}🔗${NC} Linking $label -> $item"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    (dry) ln -sfn $item $target"
  else
    ln -sfn "$item" "$target"
  fi
}

copy_file() {
  local item="$1" target="$2" label="$3"
  if [ -L "$target" ]; then
    stash "$target"
  elif [ -e "$target" ] && ! cmp -s "$item" "$target"; then
    echo "    ${YELLOW}!${NC} $label differs locally; the machine copy wins for you to capture via sync.sh"
    stash "$target"
  fi
  if cmp -s "$item" "$target" 2>/dev/null; then
    echo "    ${GREEN}✓${NC} $label already up to date."
    return 0
  fi
  echo "    ${BLUE}📄${NC} Copying $label <- $item"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    (dry) cp $item $target"
  else
    mkdir -p "$(dirname "$target")"
    cp "$item" "$target"
  fi
}

contains() {
  local needle="$1"; shift
  local x
  for x in "$@"; do
    [ "$x" = "$needle" ] && return 0
  done
  return 1
}

echo "==> Deploying configuration from $DOTFILES_DIR"
[ "$DRY_RUN" -eq 1 ] && echo "    (dry run: nothing will be written)"

do_it mkdir -p "$HOME/.config" "$HOME/.local/bin"

for item in "$DOTFILES_DIR/.config"/*; do
  name="$(basename "$item")"
  target="$HOME/.config/$name"

  if contains "$name" "${REPO_ONLY[@]}"; then
    echo "    -- $name is repo-only (used by scripts), not deployed"
    continue
  fi

  if contains "$name" "${LINK_APPS[@]}"; then
    if [ -d "$item" ]; then
      link_path "$item" "$target" "~/.config/$name"
    else
      echo "    ${YELLOW}!${NC} $name is in LINK_APPS but is a file, not a directory; skipping"
    fi
    continue
  fi

  # copy-mode apps: only the single tracked file, never the whole directory
  handled=0
  for entry in "${COPY_APPS[@]}"; do
    if [ "${entry%%:*}" = "$name" ]; then
      file="${entry#*:}"
      if [ -f "$item/$file" ]; then
        copy_file "$item/$file" "$target/$file" "~/.config/$name/$file"
      fi
      handled=1
    fi
  done
  if [ "$handled" -eq 1 ]; then
    continue
  fi

  if contains "$name" "${COPY_FILES[@]}"; then
    copy_file "$item" "$target" "~/.config/$name"
    continue
  fi

  echo "    ${YELLOW}!${NC} $name is not listed in scripts/manifest; left alone"
done

for name in "${LINK_HOME[@]}"; do
  item="$DOTFILES_DIR/home/$name"
  if [ ! -e "$item" ]; then
    echo "    ${YELLOW}!${NC} home/$name missing from the repo; skipping"
    continue
  fi
  link_path "$item" "$HOME/$name" "~/$name"
done

for item in "$DOTFILES_DIR/home"/.* "$DOTFILES_DIR/home"/*; do
  [ -e "$item" ] || continue
  name="$(basename "$item")"
  case "$name" in '.' | '..' | '.git') continue ;; esac
  contains "$name" "${LINK_HOME[@]}" && continue
  echo "    ${YELLOW}!${NC} $name in home/ is not listed in scripts/manifest; left alone"
done

if [ "$DRY_RUN" -eq 0 ]; then
  chmod +x "$DOTFILES_DIR/.config/polybar/scripts"/*.sh 2>/dev/null || true
  chmod +x "$DOTFILES_DIR/.config/polybar/launch.sh" 2>/dev/null || true
  chmod +x "$DOTFILES_DIR/scripts"/*.sh 2>/dev/null || true
fi

echo "==> Deploy complete!"
if [ "$DRY_RUN" -eq 0 ] && [ -d "$BACKUP_DIR" ]; then
  echo "==> Previous copies were kept in: $BACKUP_DIR"
  echo "    (delete it once you are happy with the session)"
fi
