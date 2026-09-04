#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.config_backup_$(date +'%Y%m%d_%H%M%S')"

echo "==> Deploying configuration symlinks from $DOTFILES_DIR..."

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"

# Symlink all folders in .config/
for item in "$DOTFILES_DIR/.config"/*; do
  name="$(basename "$item")"
  target="$HOME/.config/$name"

  # If target exists and is a symlink pointing to dotfiles, skip backup
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$item")" ]; then
    echo "    ✓ ~/.config/$name already linked."
    continue
  fi

  # If target exists and is a real directory/file, back it up
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "    📦 Backing up existing ~/.config/$name -> $BACKUP_DIR/"
    mv "$target" "$BACKUP_DIR/"
  fi

  echo "    🔗 Linking ~/.config/$name -> $item"
  ln -sfn "$item" "$target"
done

# Symlink files in home/
if [ -d "$DOTFILES_DIR/home" ]; then
  for item in "$DOTFILES_DIR/home"/.[!.]* "$DOTFILES_DIR/home"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    target="$HOME/$name"

    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$item")" ]; then
      echo "    ✓ ~/$name already linked."
      continue
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
      mkdir -p "$BACKUP_DIR"
      echo "    📦 Backing up existing ~/$name -> $BACKUP_DIR/"
      mv "$target" "$BACKUP_DIR/"
    fi

    echo "    🔗 Linking ~/$name -> $item"
    ln -sfn "$item" "$target"
  done
fi

# Ensure scripts are executable
chmod +x "$DOTFILES_DIR/.config/niri/scripts"/*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR/.config/waybar/scripts"/*.sh 2>/dev/null || true

# Symlink custom screenshot binary to ~/.local/bin/screenshot
if [ -f "$HOME/.config/niri/scripts/screenshot.sh" ]; then
  ln -sfn "$HOME/.config/niri/scripts/screenshot.sh" "$HOME/.local/bin/screenshot"
fi

echo "==> Deploy complete!"
[ -d "$BACKUP_DIR" ] && echo "==> Backups saved to: $BACKUP_DIR"
