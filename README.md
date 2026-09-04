# 🪐 Ali's CachyOS + Niri Dotfiles

Complete, reproducible, and automated configuration for **CachyOS Linux** featuring the **Niri** scrollable tiling Wayland compositor, **Waybar**, **Ly** display manager, and **Fish** shell.

---

## 🖥️ System & Tech Stack

| Component | Software |
| :--- | :--- |
| **OS** | [CachyOS](https://cachyos.org/) (Arch Linux derivative with performance kernel) |
| **Compositor** | [Niri](https://github.com/YaLTeR/niri) (Scrollable tiling Wayland compositor) |
| **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) (with workspace & language monitor) |
| **Display Manager**| [Ly](https://github.com/fairyglade/ly) (Lightweight TUI display manager) |
| **Shell** | [Fish](https://fishshell.com/) (with custom aliases & completions) |
| **Terminals** | [Kitty](https://sw.kovidgoyal.net/kitty/) & [Alacritty](https://alacritty.org/) |
| **Application Launcher** | [Fuzzel](https://codeberg.org/dnkl/fuzzel) (Wayland dmenu-compatible) |
| **Notification Daemon** | [Mako](https://github.com/emersion/mako) |
| **Screenshot & Annotation**| `grim` + `slurp` + [Satty](https://github.com/gabm/Satty) |
| **Screen Locker & Idle** | [Swaylock](https://github.com/swaywm/swaylock) & [Swayidle](https://github.com/swaywm/swayidle) |
| **Color Scheme** | Catppuccin Mocha / Macchiato theme |

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
3. Install foreign/AUR packages from [`packages/aur-explicit.txt`](packages/aur-explicit.txt) (`audiorelay`, `gitkraken`, `spotify-adblock-git`, `rustdesk`).
4. Safely backup any existing configurations and symlink all `.config` files.
5. Set default shell to **Fish** and enable **Ly** login manager.

---

## ⌨️ Keybindings & Shortcuts (`Mod` = `Super` / `Windows`)

### Core Applications
- **`Super + Enter`** or **`Super + T`**: Terminal (`kitty`)
- **`Super + Alt + T`**: Alternative Terminal (`alacritty`)
- **`Super + B`**: Web Browser (`librewolf`)
- **`Super + E`**: File Manager (`nemo`)
- **`Super + Alt + B`**: System Monitor (`btop` in kitty)
- **`Super + Shift + A`**: AudioRelay
- **`Super + D`**: App Launcher (`fuzzel`)
- **`Super + Ctrl + V`**: Code Editor (`vscodium`)
- **`Super + Shift + S`**: Spotify
- **`Super + Shift + P`**: Audio Settings (`pavucontrol`)
- **`Super + Shift + ?`**: Interactive hotkey overlay

### Keyboard Layout & Typing
- **`Alt + Shift`** / **`Shift + Alt`**: Toggle between **English (US)** and **Arabic (ara)** layouts.
- Active layout (`EN` / `AR`) is displayed in real-time in the top Waybar.

### Screenshots
- **`Print`**: Interactive area selection with annotation editor (**Satty**) (draw arrows, boxes, blur, text, crop, copy).
- **`Ctrl + Print`**: Capture full screen to `~/Pictures/Screenshots/` and clipboard.
- **`Alt + Print`**: Capture window/area to Satty editor.
- **`Super + Print`**: Quick area select directly to clipboard.

---

## 📁 Repository Structure

```text
~/dotfiles/
├── .config/
│   ├── niri/           # Window manager, layout, and keybindings
│   ├── waybar/         # Status bar config, CSS, and power menu
│   ├── fish/           # Custom aliases, completions, and config
│   ├── kitty/          # Kitty terminal colors and font settings
│   ├── alacritty/      # Alacritty configuration
│   ├── fuzzel/         # App launcher styling
│   ├── satty/          # Screenshot annotation config
│   ├── mako/           # Notification styling
│   ├── swayidle/       # Idle timer & auto-lock
│   ├── swaylock/       # Lockscreen styling
│   ├── btop/           # Resource monitor theme
│   ├── lazygit/        # Terminal Git UI config
│   └── gtk-3.0/        # GTK themes & dark mode
├── home/
│   └── .gitconfig      # Git identity & gh credential helper
├── packages/
│   ├── core-apps.txt   # Curated list of desktop stack
│   ├── pacman-explicit.txt # Full list of native packages
│   └── aur-explicit.txt    # AUR packages (audiorelay, gitkraken, etc.)
├── scripts/
│   ├── backup.sh       # Updates package lists from current system
│   └── deploy.sh       # Symlinks dotfiles into ~/.config and ~
├── install.sh          # One-click bootstrap installer
└── README.md
```

---

## 🔄 How to Keep Dotfiles Updated

Because your configurations in `~/.config/` are symlinked to `~/dotfiles/.config/`, any edits you make are automatically inside the git repository.

To sync new packages and push changes to GitHub:

```bash
cd ~/dotfiles
./scripts/backup.sh
git add .
git commit -m "Update configuration"
git push
```
