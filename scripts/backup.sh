#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Updating package lists..."
pacman -Qne | awk '{print $1}' | sort -u > "$DOTFILES_DIR/packages/pacman-explicit.txt"
pacman -Qme | awk '{print $1}' | sort -u > "$DOTFILES_DIR/packages/aur-explicit.txt"

echo "==> Package lists updated:"
echo "    - Native: $(wc -l < "$DOTFILES_DIR/packages/pacman-explicit.txt") packages"
echo "    - AUR:    $(wc -l < "$DOTFILES_DIR/packages/aur-explicit.txt") packages"

echo ""
echo "==> Git Status:"
cd "$DOTFILES_DIR"
git status -s
