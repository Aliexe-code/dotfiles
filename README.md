# 🪐 Ali's Fedora + i3 Dotfiles

Reproducible configuration for **Fedora 44 (i3 spin)**: the **[i3](https://i3wm.org/)** tiling window manager on **X11**, **Polybar**, **Rofi**, **Dunst**, **Picom**, the **zsh** shell, and **ghostty** (terminal and `btop` host).

> Reinstalling? Jump to [Quick Start](#-quick-start-on-a-fresh-fedora-install).

This repo is the **only** place these configs exist. Most of `~/.config` is symlinked into it, so an edit you make in your session is an edit to the repo.

---

## 🖥️ System & Tech Stack

| Component | Software |
| :--- | :--- |
| **OS** | Fedora 44, i3 spin (X11, `lightdm`) |
| **Window Manager** | [i3](https://i3wm.org/) |
| **Status Bar** | [Polybar](https://polybar.github.io/) — the bar is named `top` |
| **Launcher** | [Rofi](https://github.com/davatorium/rofi) (`drun`, `ssh`, power menu) |
| **Notifications** | [Dunst](https://dunst-project.org/) |
| **Compositor** | [Picom](https://github.com/yshui/picom) |
| **Display Manager** | LightDM (`lightdm-gtk` greeter) |
| **Shell** | zsh + oh-my-zsh (`robbyrussell`; autosuggestions, syntax-highlighting) |
| **Terminal** | ghostty (`$term`), xfce4-terminal kept as fallback |
| **Editor** | [Neovim](https://neovim.io/) (kickstart-based) & [VSCodium](https://vscodium.com/) (`codium`) |
| **Terminal Workspace** | [zellij](https://zellij.dev/) |
| **Coding Agents** | opencode, kilo |
| **Browsers** | Zen (`$browser`) + LibreWolf |
| **Screenshots** | [Spectacle](https://apps.kde.org/spectacle/) |
| **Wallpaper / Lock** | `feh` / `xsecurelock` (`Mod+l`); the power menu locks with `i3lock` |
| **File Manager** | Nemo (Thunar also present from the spin) |
| **Colors** | Nord palette (`#2E3440` / `#88C0D0`), Adwaita GTK theme, Breeze icons |
| **Font** | **JetBrainsMono Nerd Font** — see the warning below |

---

## ⚡ Quick Start on a Fresh Fedora Install

```bash
git clone https://github.com/Aliexe-code/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/provision.sh --dry-run   # read what it would do, change nothing
./scripts/provision.sh             # do it
```

Steps, each idempotent and individually runnable (`--only fonts`):

1. `i3check` — reports whether i3/lightdm are as expected; reminds you about browsers.
2. `repos` — installs `packages/third-party/vscodium.repo` if it is not already enabled.
3. `packages` — `dnf install` of [`packages/core-apps.txt`](packages/core-apps.txt). A name that doesn't resolve becomes a warning, not a failed run.
4. `flatpak` — Flathub + [`packages/flatpak.txt`](packages/flatpak.txt) (Zen, AudioRelay).
5. `fonts` — JetBrainsMono Nerd Font via [`scripts/install-fonts.sh`](scripts/install-fonts.sh).
6. `zsh` — sets the login shell, using whichever zsh path `/etc/shells` lists.
7. `ohmyzsh` — clones oh-my-zsh plus the two plugins `home/.zshrc` expects.
8. `deploy` — [`scripts/deploy.sh`](scripts/deploy.sh) links/copies configs into place.

> ⚠️ **The Nerd Font is not optional, and `dnf` cannot provide it.** Fedora's
> `jetbrains-mono-fonts` package has no Nerd glyphs. Polybar (`config.ini`
> `font-0`/`font-1`), Rofi, `ghostty` config and `xsettingsd.conf` all name
> "JetBrainsMono Nerd Font", so without step 5 the bar renders tofu boxes.
> `install-fonts.sh` downloads the ~130MB upstream zip, keeps the 8 faces
> actually referenced, and **fails loudly** if fontconfig still falls back.

Log out and back in at LightDM to start the i3 session.

---

## 🌐 Browsers: intentionally untracked

LibreWolf keeps a 276M profile at `~/.config/librewolf`, Zen a 526M one at `~/.var/app/app.zen_browser.zen`. Both hold cookies, history, session data and saved passwords, so **this repo commits none of it** — `.gitignore` blocks the file shapes and `scripts/manifest` denies the directories.

After provisioning a new machine: sign in again, or use each browser's own sync. Bookmarks, extensions and preferences will not come from here.

---

## ⌨️ Keybindings (`Mod` = `Super` / `Windows`)

### Applications
| Key | Action |
| :--- | :--- |
| `Mod + Return` | Terminal (`$term` = ghostty) |
| `Mod + d` | App launcher (`rofi -show drun`) |
| `Mod + b` | Browser (`$browser` = zen) |
| `Mod + Shift + b` | Tor Browser |
| `Mod + e` | Editor (`codium`) |
| `Mod + Shift + n` | File manager (`nemo`) |
| `Mod + Shift + s` | SSH launcher (`rofi -show ssh`) |
| `Mod + grave` / `Mod + Ctrl + Return` | `btop` in a ghostty window |
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
| `Mod + Shift + w` | Sticky toggle |
| `Mod + a` / `Mod + z` | Focus parent / child |
| `Mod + r` then arrows | Enter resize mode |
| `Mod + ←↓↑→` | Focus window |
| `Mod + Shift + ←↓↑→` | Move window |

### Workspaces
`Mod + 1..0` switch, `Mod + Shift + 1..0` move. Named: `1: Web`, `2: Code`, `3: Term`, `4: Chat`, `5: Files`, then 6–10.

### Session
| Key | Action |
| :--- | :--- |
| `Mod + l` | Lock (`xsecurelock`) |
| `Mod + Shift + x` / `Mod + Shift + z` | Power menu (`polybar/scripts/power.sh`; its lock item uses `i3lock`) |
| `Mod + Shift + e` | Exit i3 (via `i3-nagbar`) |
| `Mod + Shift + c` / `Mod + Shift + r` | Reload / restart i3 |

### Keyboard Layout & Media
- **`Alt + Shift`**: toggle **US** ↔ **Arabic (EG)** (`setxkbmap -layout us,eg -variant ,basic`)
- **Volume**: `XF86Audio*` → `pamixer`
- **Media**: `XF86AudioPlay/Next/Prev` → `playerctl`
- **Brightness**: `XF86MonBrightness*` → `brightnessctl`

---

## 🚀 Autostarted at Login (from `i3/config`)

`xset s off -dpms` (blanking off) · `xrandr --auto` · `feh --bg-fill` · `picom` · `dunst` · **`/usr/libexec/xfce-polkit`** · `setxkbmap` · `polybar/launch.sh` · a terminal on workspace 1.

> The polkit agent line used to run `/usr/libexec/lxpolkit`, an Arch path. On
> Fedora the agent is `xfce-polkit`, so with the old line GUI authentication
> prompts were silently going unanswered.

> `polybar/config.ini` defaults `monitor` to `DP-0` while `launch.sh` starts one
> bar per connected output reported by `xrandr`. Adjust if your display differs.

---

## 📁 Repository Structure

```text
~/dotfiles/
├── .config/
│   ├── i3/             # Window manager config + wallpaper
│   ├── polybar/        # Status bar (bar name: top), scripts, power menu
│   ├── rofi/           # Launcher config
│   ├── dunst/          # Notification daemon
│   ├── picom/          # Compositor
│   ├── ghostty/        # Ghostty (terminal + btop host)
│   ├── nvim/           # Neovim (kickstart-based) + language plugins
│   ├── zellij/         # config.kdl
│   ├── fontconfig/     # Font rendering
│   ├── xsettingsd/     # Xft/GTK settings daemon
│   ├── gtk-3.0/        # GTK theme & dark mode
│   ├── btop/           # Resource monitor (copy-managed)
│   ├── opencode/       # opencode.jsonc only (copy-managed)
│   ├── kilo/           # kilo.jsonc only (copy-managed)
│   ├── lazygit/        # empty placeholder; still on defaults
│   ├── spectacle/      # KDE shortcut snippet — reference only, never deployed
│   ├── spectaclerc     # Screenshot settings (copy-managed)
│   └── mimeapps.list   # Default applications (copy-managed)
├── home/
│   ├── .zshrc          # zsh + oh-my-zsh, aliases, dotpush/dotstatus
│   ├── .zshenv
│   └── .gitconfig      # Git identity & gh credential helper
├── packages/
│   ├── core-apps.txt            # Hand-curated install list (dnf)
│   ├── flatpak.txt              # Hand-curated flatpak app IDs
│   ├── dnf-userinstalled.txt    # GENERATED snapshot — reference only
│   └── third-party/vscodium.repo
├── scripts/
│   ├── manifest                 # What is tracked, and link vs copy per entry
│   ├── provision.sh             # Fresh-machine bootstrap (dnf/flatpak/fonts)
│   ├── deploy.sh                # repo -> home (symlink or copy)
│   ├── sync.sh                  # home -> repo (allowlist capture)
│   ├── backup.sh                # regenerate packages/dnf-userinstalled.txt
│   ├── install-fonts.sh         # JetBrainsMono Nerd Font
│   └── restore-screenshot-keys.sh
└── README.md
```

---

## 🔄 How to Keep Dotfiles Updated

Two modes, defined in [`scripts/manifest`](scripts/manifest):

- **link** (`i3`, `polybar`, `picom`, `rofi`, `dunst`, `ghostty`, `fontconfig`, `gtk-3.0`, `xsettingsd`, `nvim`, `lazygit`, `zellij`, plus `~/.zshrc`, `~/.zshenv`, `~/.gitconfig`) — the repo file *is* the live file, so edits are tracked instantly.
- **copy** (`btop`, `opencode`, `kilo`, `mimeapps.list`, `spectaclerc`) — these rewrite their own config directory (opencode drops `node_modules/` and `service.json` beside its jsonc; btop rewrites `btop.conf` on exit). Symlinking them would fill `git status` with generated junk, so they are copied out and captured back on demand.

Push everything from anywhere:

```bash
dotpush      # sync.sh + backup.sh + git add/commit/push (defined in .zshrc)
```

Or step by step:

```bash
~/dotfiles/scripts/sync.sh --dry-run   # show what would be captured
~/dotfiles/scripts/sync.sh             # capture copy-managed edits
~/dotfiles/scripts/backup.sh           # refresh the package snapshot
git -C ~/dotfiles status
```

`sync.sh` refuses anything in its `FORBIDDEN` list and anything whose filename
looks secret-shaped. That is deliberate — it is why there is no blanket "sync all
of `~/.config`" option.

### Re-applying the configs

```bash
~/dotfiles/scripts/deploy.sh --dry-run
~/dotfiles/scripts/deploy.sh
```

Idempotent: already-linked entries are skipped, anything replaced moves to
`~/.config_backup_<timestamp>/`, and a `.config/` entry missing from the
manifest is left alone with a warning rather than guessed at.

### Not covered by this repo

`zellij` (GitHub release binary in `~/.local/bin`), `lazygit`
(`go install github.com/jesseduffield/lazygit@latest`), and the V, Zig, bun and
Node toolchains — each installed by its own upstream, and each left alone on
purpose so this repo stays about configuration.
