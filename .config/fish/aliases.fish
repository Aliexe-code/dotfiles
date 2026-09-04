# =====================================================================
# fish aliases — CachyOS professional setup
# Sourced from config.fish.
# Reload with:  source ~/.config/fish/aliases.fish
# =====================================================================

# Reload these aliases without restarting the shell
alias reload  "source ~/.config/fish/aliases.fish"

# ---------------------------------------------------------------------
# System updates (Arch / CachyOS)
# ---------------------------------------------------------------------
alias up       "sudo pacman -Syu; and paru -Sau"   # update repos (pacman) + AUR (paru)
alias check    "paru -Qu"           # list available updates, don't install
alias yay      paru                 # common alias for the AUR helper

# paru / pacman
alias pin      "paru -S"            # install package(s)
alias prm      "paru -Rns; and sudo paccache -ruk0"   # remove pkg(s) + free cached tarballs
alias del      "sudo pacman -Rns; and sudo paccache -ruk0"   # delete pkg(s) + free cached tarballs
alias psearch  "pacman -Ss"         # search packages
alias pshow    "pacman -Qi"         # show info about an installed package
alias pclean   "checkupdates"       # pending repo-only updates
alias porn     "pacman -Qtdq"       # list orphaned packages
alias porph     "pacman -Qtdq | sudo pacman -Rns -"   # remove orphaned packages (frees leftover deps)
alias pkeys    "pacman-key --refresh-keys"

# ---------------------------------------------------------------------
# Go (backend development)
# ---------------------------------------------------------------------
alias gob      "go build ./..."
alias gor      "go run ."
alias got      "go test ./..."
alias god      "go build -o /dev/null ./..."     # fast compile check
alias gov      "go vet ./..."
alias gott     "go test -v ./..."
alias gotr     "go test -race ./..."
alias gfmt     "gofmt -w ."
alias gcheck   "gofmt -l ."                        # list not-formatted files
alias gmod     "go mod tidy"
alias gget     "go get"
alias gcln     "go clean -cache"
alias gbuild   "env GOOS=linux GOARCH=amd64 go build"   # cross-compile linux
alias gpath    'echo "GOPATH: $GOPATH\nGOROOT: $GOROOT"'

# ---------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------
alias g        "git"
alias gst      "git status"
alias ga       "git add"
alias gaa      "git add -A"
alias gc       "git commit -m"
alias gca      "git commit --amend "
alias gp       "git push"
alias gup      "git pull --rebase"
alias gl       "git log --oneline --graph --decorate -20"
alias gdiff    "git diff"
alias gdiffc   "git diff --cached"
alias gb       "git branch -a"
alias gco      "git checkout"
alias gcb      "git checkout -b"
alias gundo    "git reset HEAD~1"
alias gclone   "git clone"
alias gtree    "git log --graph --pretty=oneline --abbrev-commit --all"
alias lg       "lazygit"          # Git TUI

# ---------------------------------------------------------------------
# System control
# ---------------------------------------------------------------------
alias sys      "systemctl"
alias sst      "systemctl status"
alias sre      "systemctl restart"
alias sstop    "systemctl stop"
alias sstart   "systemctl start"
alias senab    "systemctl enable --now"
alias slog     "journalctl -xe"
alias sfollow  "journalctl -f"

# ---------------------------------------------------------------------
# Files & navigation
# ---------------------------------------------------------------------
alias ll       "ls -lah"
alias la       "ls -A"
alias mkd      "mkdir -p"
alias ..       "cd .."
alias ...      "cd ../.."
alias home     "cd ~"
alias dev      "cd ~/Projects"

# ---------------------------------------------------------------------
# Dev / networking tools
# ---------------------------------------------------------------------
alias ports    "ss -tulpn"          # list listening ports
alias procs    "ps aux | rg"
alias myip     'curl -s ifconfig.me; echo'
alias pubip    "curl -s ifconfig.me"
alias dns      "resolvectl status"

# ---------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------
alias ff       "fastfetch"
alias weather  "curl -s wttr.in | head -20"

# ---------------------------------------------------------------------
# Dotfiles management
# ---------------------------------------------------------------------
alias dotpush   "cd ~/dotfiles; and ./scripts/backup.sh; and git add .; and git commit -m (date '+%Y-%m-%d %H:%M:%S'); and git push; and cd -"
alias dotstatus "cd ~/dotfiles; and git status; and cd -"
alias dotcd     "cd ~/dotfiles"

