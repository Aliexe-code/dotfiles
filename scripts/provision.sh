#!/usr/bin/env bash
# Provision a fresh Fedora 44 (i3 spin) machine from this repo.
# Replaces the old install.sh, which hard-exited unless pacman existed.
#
#   ./scripts/provision.sh                 # every step
#   ./scripts/provision.sh --dry-run       # show what would run
#   ./scripts/provision.sh --only fonts    # subset (comma-separated)
#
# Steps: i3check packages flatpak fonts zsh ohmyzsh deploy
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
ONLY=""
STEPS="i3check repos packages flatpak fonts zsh ohmyzsh deploy"

usage() {
  echo "usage: $0 [--dry-run] [--only $(echo $STEPS | tr ' ' ',')]" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n | --dry-run) DRY_RUN=1 ;;
    --only)
      [ $# -ge 2 ] || usage
      ONLY="$2"
      shift
      ;;
    -h | --help) usage ;;
    *) usage ;;
  esac
  shift
done

c_blue=$'\033[0;34m'; c_grn=$'\033[0;32m'; c_yel=$'\033[1;33m'; c_red=$'\033[0;31m'; c_off=$'\033[0m'
if [ ! -t 1 ]; then c_blue=""; c_grn=""; c_yel=""; c_red=""; c_off=""; fi

# Progress chatter goes to stderr: filter_installable() prints package names on
# stdout and gets captured, so a note() there would end up inside the dnf args.
step() { echo "${c_blue}==> $*${c_off}" >&2; }
note() { echo "${c_yel}    ! $*${c_off}" >&2; }
ok() { echo "${c_grn}    ✓ $*${c_off}" >&2; }
die() { echo "${c_red}ERROR: $*${c_off}" >&2; exit 1; }

wanted() {
  case ",${ONLY}," in
    '' | ',,') return 0 ;;
  esac
  case ",$ONLY," in
    *",$1,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    (dry) $*"
    return 0
  fi
  "$@"
}

# One repoquery call for the whole list: a package that moved to COPR, or a
# typo, degrades to a warning instead of aborting the install.
filter_installable() {
  local file="$1" n
  local names=()
  while read -r n; do
    names+=("$n")
  done < <(grep -vE '^\s*(#|$)' "$file")
  dnf repoquery --available --qf '%{name}\n' "${names[@]}" 2>/dev/null | sort -u >"$tmp_dir/available"
  for n in "${names[@]}"; do
    if grep -qxF "$n" "$tmp_dir/available"; then
      printf '%s\n' "$n"
    else
      note "skipping '$n': not in any enabled Fedora repo"
    fi
  done
}

step_i3check() {
  step "Checking what this config expects from the OS"
  if rpm -q i3 >/dev/null 2>&1; then
    ok "i3 $(rpm -q --qf '%{version}' i3) present (Fedora i3 spin)"
  else
    note "i3 absent; core-apps.txt pulls it, but the i3 spin is the intended base"
  fi
  if systemctl is-enabled lightdm >/dev/null 2>&1; then
    ok "lightdm enabled — this session is X11 (the old Arch setup used ly)"
  else
    note "lightdm is not enabled; these configs need an X11 session"
  fi
  if [ -z "$ONLY" ]; then
    echo "    ${c_yel}!${c_off} Browser profiles are not provisioned by design:"
    echo "      LibreWolf ~/.config/librewolf, Zen ~/.var/app/app.zen_browser.zen"
    echo "      Re-sign in, or use each browser's own sync."
  fi
}

step_repos() {
  step "Third-party repo definitions (packages/third-party/*.repo)"
  local f repoid
  for f in "$DOTFILES_DIR"/packages/third-party/*.repo; do
    [ -e "$f" ] || continue
    repoid="$(grep -m1 -oE '^\[[^]]+\]' "$f" | tr -d '[]')"
    if [ -z "$repoid" ]; then
      note "$f has no [section] header; skipping"
      continue
    fi
    if dnf repolist -q "$repoid" >/dev/null 2>&1; then
      ok "$repoid already enabled"
    else
      echo "    copying repo definition for $repoid (sudo)" >&2
      run sudo cp "$f" "/etc/yum.repos.d/$repoid.repo"
    fi
  done
}

step_packages() {
  step "Installing curated packages (packages/core-apps.txt)"
  local list
  list="$(filter_installable "$DOTFILES_DIR/packages/core-apps.txt")"
  [ -n "$list" ] || die "no installable packages resolved from core-apps.txt"
  echo "    $(printf '%s\n' "$list" | wc -l) of $(grep -cvE '^\s*(#|$)' "$DOTFILES_DIR/packages/core-apps.txt") names available; installing (sudo)"
  # shellcheck disable=SC2086
  run sudo dnf install -y $list || note "some packages failed; continuing"
}

step_flatpak() {
  step "Installing flatpak apps (packages/flatpak.txt)"
  if ! command -v flatpak >/dev/null; then
    note "flatpak missing; installing it"
    run sudo dnf install -y flatpak
  fi
  run flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  local app
  while read -r app; do
    if flatpak list --app 2>/dev/null | grep -qxF "$app"; then
      ok "$app already installed"
    else
      run flatpak install -y --noninteractive flathub "$app"
    fi
  done < <(grep -vE '^\s*(#|$)' "$DOTFILES_DIR/packages/flatpak.txt")
}

step_fonts() {
  step "JetBrainsMono Nerd Font (required by polybar, rofi, kitty, xsettingsd)"
  run "$DOTFILES_DIR/scripts/install-fonts.sh"
}

step_zsh() {
  step "Default shell"
  local target="" cand
  for cand in /bin/zsh /usr/bin/zsh; do
    if grep -qxF "$cand" /etc/shells; then
      target="$cand"
      break
    fi
  done
  [ -n "$target" ] || die "no zsh entry in /etc/shells; run the packages step first"
  if [ "$(getent passwd "$USER" | cut -d: -f7)" = "$target" ]; then
    ok "login shell is already $target"
  else
    run chsh -s "$target" "$USER"
  fi
}

step_ohmyzsh() {
  step "oh-my-zsh + plugins (home/.zshrc expects these exact paths)"
  if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "~/.oh-my-zsh present"
  else
    run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi
  local p
  for p in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ -d "$HOME/.oh-my-zsh/custom/plugins/$p" ]; then
      ok "plugin $p present"
    else
      run git clone --depth=1 "https://github.com/zsh-users/$p.git" "$HOME/.oh-my-zsh/custom/plugins/$p"
    fi
  done
}

step_deploy() {
  step "Deploying config into place"
  run "$DOTFILES_DIR/scripts/deploy.sh"
}

# ---------------------------------------------------------------------
command -v dnf >/dev/null ||
  die "this script requires dnf (Fedora). The configs in this repo are still yours on any distro."

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fedora_ver="$(. /etc/os-release; echo "${VERSION_ID:-?}")"
echo "${c_blue}==========================================================${c_off}"
echo "${c_blue}    Fedora ${fedora_ver:-?} + i3 dotfiles provisioning${c_off}"
echo "${c_blue}==========================================================${c_off}"
if [ "$DRY_RUN" -eq 1 ]; then
  note "dry run: nothing will be executed"
fi

for s in $STEPS; do
  if wanted "$s"; then
    "step_$s"
  fi
done

step "Done"
echo "    Deliberately not provisioned (personal toolchains):"
echo "      zellij   -> GitHub release binary, lives in ~/.local/bin"
echo "      lazygit  -> go install github.com/jesseduffield/lazygit@latest"
echo "      V, Zig, bun, Node -> each upstream's own installer"
