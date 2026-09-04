#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ANSI Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}"
echo "=========================================================="
echo "    CachyOS + Niri + Waybar Dotfiles Installation Script  "
echo "=========================================================="
echo -e "${NC}"

# 1. Check pacman
if ! command -v pacman &>/dev/null; then
  echo -e "${RED}[ERROR] This installer requires an Arch / CachyOS based system.${NC}"
  exit 1
fi

# 2. Check / Install AUR Helper (paru)
echo -e "${YELLOW}[1/5] Checking AUR helper (paru)...${NC}"
if ! command -v paru &>/dev/null; then
  echo -e "${BLUE}Installing paru...${NC}"
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
  (cd /tmp/paru-bin && makepkg -si --noconfirm)
  rm -rf /tmp/paru-bin
else
  echo -e "${GREEN}✓ paru is already installed.${NC}"
fi

# 3. Install Native Packages
echo -e "${YELLOW}[2/5] Installing Native Packages from pacman-explicit.txt...${NC}"
if [ -f "$DOTFILES_DIR/packages/pacman-explicit.txt" ]; then
  sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/packages/pacman-explicit.txt" || {
    echo -e "${YELLOW}[WARN] Some packages failed to install in batch mode. Continuing...${NC}"
  }
fi

# 4. Install AUR Packages
echo -e "${YELLOW}[3/5] Installing AUR Packages from aur-explicit.txt...${NC}"
if [ -f "$DOTFILES_DIR/packages/aur-explicit.txt" ]; then
  paru -S --needed --noconfirm - < "$DOTFILES_DIR/packages/aur-explicit.txt" || {
    echo -e "${YELLOW}[WARN] Some AUR packages failed to install in batch mode. Continuing...${NC}"
  }
fi

# 5. Deploy Dotfiles (Symlinks)
echo -e "${YELLOW}[4/5] Deploying Dotfiles Symlinks...${NC}"
"$DOTFILES_DIR/scripts/deploy.sh"

# 6. Post-install Services & Shell
echo -e "${YELLOW}[5/5] Configuring Services and Shell...${NC}"

# Set default shell to fish if installed
if command -v fish &>/dev/null; then
  CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
  FISH_PATH="$(which fish)"
  if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
    echo -e "${BLUE}Setting default shell to fish...${NC}"
    chsh -s "$FISH_PATH" "$USER" || sudo chsh -s "$FISH_PATH" "$USER"
  fi
fi

# Enable Ly display manager if installed
if command -v ly &>/dev/null; then
  echo -e "${BLUE}Ensuring ly display manager is enabled...${NC}"
  sudo systemctl enable ly.service 2>/dev/null || sudo systemctl enable ly 2>/dev/null || true
fi

echo -e "${GREEN}${BOLD}"
echo "=========================================================="
echo "    Installation and Configuration Complete! 🎉           "
echo "=========================================================="
echo -e "${NC}"
echo -e "You can now log out or reboot to start your configured session."
