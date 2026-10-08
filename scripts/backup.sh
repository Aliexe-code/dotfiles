#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Updating package lists..."
# Wayland/Niri-era packages intentionally excluded — this repo targets the i3/X11 setup.
WAYLAND_EXCLUDE='^(niri|waybar|mako|fuzzel|satty|grim|slurp|wl-clipboard|swayidle|swaylock-effects|xwayland-satellite|sway|mangowm|cliphist)$'
pacman -Qne | awk '{print $1}' | sort -u | grep -vxE "$WAYLAND_EXCLUDE" > "$DOTFILES_DIR/packages/pacman-explicit.txt"
pacman -Qme | awk '{print $1}' | sort -u > "$DOTFILES_DIR/packages/aur-explicit.txt"

echo "==> Package lists updated:"
echo "    - Native: $(wc -l < "$DOTFILES_DIR/packages/pacman-explicit.txt") packages"
echo "    - AUR:    $(wc -l < "$DOTFILES_DIR/packages/aur-explicit.txt") packages"

echo ""
echo "==> Git Status:"
cd "$DOTFILES_DIR"
git status -s
