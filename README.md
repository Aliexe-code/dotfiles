# 🪐 Ali's CachyOS + i3 Dotfiles

Complete, reproducible, and automated configuration for **CachyOS Linux** featuring the **[i3](https://i3wm.org/)** tiling window manager (X11), **Polybar**, **Rofi**, **Ghostty**, and the **Fish** shell.

> Reinstalling? Jump to [Quick Start](#-quick-start-on-a-fresh-cachyos-install).

---

## 🖥️ System & Tech Stack

| Component | Software |
| :--- | :--- |
| **OS** | [CachyOS](https://cachyos.org/) (Arch Linux derivative with performance kernel) |
| **Window Manager** | [i3](https://i3wm.org/) (X11 tiling WM) |
| **Status Bar** | [Polybar](https://polybar.github.io/) |
| **Launcher** | [Rofi](https://github.com/davatorium/rofi) (`drun`, `ssh`, power menu) |
| **Notifications** | [Dunst](https://dunst-project.org/) |
| **Compositor** | [Picom](https://github.com/yshui/picom) |
| **Display Manager** | [Ly](https://github.com/fairyglade/ly) |
| **Shell** | [Fish](https://fishshell.com/) (custom aliases & completions) |
| **Terminal** | [Ghostty](https://ghostty.org/) |
| **Editor** | [Neovim](https://neovim.io/) (kickstart-based) & [VSCodium](https://vscodium.com/) |
| **Screenshots** | [Spectacle](https://apps.kde.org/spectacle/) |
| **Wallpaper / Lock** | `feh` / `i3lock-color` |
| **Color Scheme** | Nord |

---

## ⚡ Quick Start on a Fresh CachyOS Install

On a clean install, run this single command to clone, install all packages, and link your configurations:

```bash
git clone https://github.com/Aliexe-code/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer will:
1. Ensure `paru` (AUR helper) is installed.
2. Install all native repo packages from [`packages/pacman-explicit.txt`](packages/pacman-explicit.txt).
3. Install foreign/AUR packages from [`packages/aur-explicit.txt`](packages/aur-explicit.txt) (`audiorelay`, `discord-ptb`, `gitkraken`, `rpcs3-git`, `rustdesk`, `tiri-bin`).
4. Safely backup any existing configurations and symlink all `.config` files.
5. Set default shell to **Fish** and enable the **Ly** login manager.

After first login, verify i3 launched (start it via Ly session or `startx`).

---

## ⌨️ Keybindings (`Mod` = `Super` / `Windows`)

### Applications
| Key | Action |
| :--- | :--- |
| `Mod + Return` | Terminal (`ghostty`) |
| `Mod + d` | App launcher (`rofi -show drun`) |
| `Mod + b` | Browser (`librewolf`) |
| `Mod + Shift + b` | Tor Browser |
| `Mod + e` | Editor (`vscodium`) |
| `Mod + Shift + n` | File manager (`nemo`) |
| `Mod + Shift + s` | SSH launcher (`rofi -show ssh`) |
| `Mod + grave` / `Mod + Ctrl + Return` | `btop` in a Ghostty window |
| `Mod + m` | Spotify |
| `Mod + Shift + a` | AudioRelay |
| `Mod + Shift + p` | Calculator (`gnome-calculator`) |

### Screenshots (Spectacle)
| Key | Action |
| :--- | :--- |
| `Print` | Capture region (`spectacle -r`) |
| `Shift + Print` | Capture full screen (`spectacle -f`) |
| `Mod + Print` | Capture active window (`spectacle -a`) |

### Window Management
| Key | Action |
| :--- | :--- |
| `Mod + h` / `Mod + v` | Split horizontal / vertical |
| `Mod + t` | Toggle split |
| `Mod + s` / `Mod + w` | Stacking / tabbed layout |
| `Mod + f` | Fullscreen toggle |
| `Mod + Shift + space` | Toggle floating |
| `Mod + space` | Toggle focus tiling/floating |
| `Mod + a` / `Mod + z` | Focus parent / child |
| `Mod + r` then arrows | Enter resize mode |
| `Mod + ←↓↑→` | Focus window |
| `Mod + Shift + ←↓↑→` | Move window |

### Workspaces
| Key | Action |
| :--- | :--- |
| `Mod + 1..0` | Switch to workspace 1–10 |
| `Mod + Shift + 1..0` | Move container to workspace 1–10 |

### Session
| Key | Action |
| :--- | :--- |
| `Mod + l` | Lock screen (`i3lock`) |
| `Mod + Shift + x` / `Mod + Shift + z` | Power menu (`polybar/scripts/power.sh`) |
| `Mod + Shift + e` | Exit i3 |
| `Mod + Shift + c` / `Mod + Shift + r` | Reload / restart i3 |

### Keyboard Layout & Media
- **`Alt + Shift`**: toggle **US** ↔ **Arabic (EG)** layouts (`setxkbmap`).
- **Volume**: `XF86Audio*` keys drive `pamixer`, with an on-screen bar via `xob`.
- **Media**: `XF86AudioPlay/Next/Prev` via `playerctl`.
- **Brightness**: `XF86MonBrightness*` via `brightnessctl`.

---

## 🚀 Autostarted at Login (from `i3/config`)

`feh` (wallpaper) · `picom` (compositor) · `dunst` (notifications) · `polybar` · `dex` (XDG autostart) · polkit-gnome agent · xob volume OSD.

> The i3 config pins monitor `DP-0` at `1920x1080 @ 143.85Hz`. Adjust the `xrandr` line if your display differs.

---

## 📁 Repository Structure

```text
~/dotfiles/
├── .config/
│   ├── i3/             # Window manager config + wallpaper
│   ├── polybar/        # Status bar config, scripts, power menu, launch.sh
│   ├── rofi/           # Launcher theme & config
│   ├── dunst/          # Notification daemon
│   ├── picom/          # Compositor
│   ├── ghostty/        # Terminal
│   ├── fish/           # Shell config, aliases, completions
│   ├── nvim/           # Neovim (kickstart-based) with tooling plugins
│   ├── fontconfig/     # Font rendering
│   ├── xsettingsd/     # Xft/GTK settings daemon
│   ├── gtk-3.0/        # GTK themes & dark mode
│   ├── kitty/          # Kitty terminal config
│   ├── alacritty/      # Alacritty terminal config
│   ├── btop/           # Resource monitor theme
│   ├── lazygit/        # Terminal Git UI config
│   ├── spectacle/      # KDE shortcut snippet (reference)
│   ├── spectaclerc     # Screenshot settings
│   └── mimeapps.list   # Default applications
├── home/
│   └── .gitconfig      # Git identity & gh credential helper
├── packages/
│   ├── core-apps.txt          # Curated desktop stack
│   ├── pacman-explicit.txt    # Full native package list
│   └── aur-explicit.txt       # AUR packages
├── scripts/
│   ├── backup.sh              # Refresh package lists from current system
│   ├── deploy.sh              # Symlink dotfiles into ~/.config and ~/
│   └── restore-screenshot-keys.sh
├── install.sh          # One-click bootstrap installer
└── README.md
```

---

## 🔄 How to Keep Dotfiles Updated

Configurations in `~/.config/` are **symlinked** to `~/dotfiles/.config/`, so any edit you make is immediately inside the git repo.

To refresh package lists and push changes:

```bash
cd ~/dotfiles
./scripts/backup.sh
git add .
git commit -m "Update configuration"
git push
```

### Re-applying the symlinks

If a config gets unlinked (e.g. an app recreates it), re-run:

```bash
./scripts/deploy.sh
```

It is idempotent: already-linked entries are skipped, and anything it replaces is moved to `~/.config_backup_<timestamp>/`.
