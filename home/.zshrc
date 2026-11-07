export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme (clean, no host/fedora branding)
ZSH_THEME="robbyrussell"

# Plugins
plugins=(
  git
  golang
  zsh-autosuggestions
  zsh-syntax-highlighting
  sudo
  history
)

source "$ZSH/oh-my-zsh.sh"

# Case-insensitive completion: `cd desktop<Tab>` matches `Desktop`
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' menu select

# Syntax highlighting colors: valid commands green, unknown/red tokens red
ZSH_HIGHLIGHT_STYLES[command]='fg=green'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
ZSH_HIGHLIGHT_STYLES[function]='fg=green'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold,underline'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=yellow'

# ---- Development shortcuts ----

# Go
alias gob='go build'
alias gor='go run'
alias got='go test ./...'
alias gom='go mod tidy'
alias goi='go install'
alias gov='go version'
# zig
alias zb='zig build'
alias zr='zig run'
alias zt='zig test'
alias zf='zig fmt'
alias zv='zig version'
alias zex='zig build-exe'
# V
alias vb='v .'
alias vr='v run'
alias vfmt='v fmt'
alias vtest='v test'
alias vprod='v -prod'
alias vver='v version'

# General dev aliases
alias ll='ls -la --color=auto'
alias t='eza --tree --level=2 --icons'
alias ta='eza --tree --level=3 --icons --all'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias lg='lazygit'
alias reload='source ~/.zshrc'

# Quick project shortcuts
alias dev='cd ~/dev 2>/dev/null || mkdir -p ~/dev && cd ~/dev'
alias projects='cd ~/projects 2>/dev/null || mkdir -p ~/projects && cd ~/projects'

# Qoder
alias qoder=qodercli

# Functions
# Create and cd into dir
mkcd() { mkdir -p "$1" && cd "$1"; }

# Go new module
gonew() { mkdir -p "$1" && cd "$1" && go mod init "$1" && echo "module $1 ready"; }

# Zig new project
ziginit() { zig init "$@"; }

# V new project
vnew() { mkdir -p "$1" && cd "$1" && v init . 2>/dev/null; echo "v project $1 ready"; }

# Run tests based on detected language
test() {
  if [ -f go.mod ]; then go test ./...
  elif [ -f build.zig ]; then zig build test
  elif [ -f v.mod ]; then v test .
  else echo "No recognized project (go.mod/build.zig/v.mod)"
  fi
}

# Build based on detected language
build() {
  if [ -f go.mod ]; then go build ./...
  elif [ -f build.zig ]; then zig build
  elif [ -f v.mod ]; then v .
  else echo "No recognized project"
  fi
}

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Completion
autoload -Uz compinit && compinit

# Prompt customization: ensure no "fedora" branding
# (robbyrussell theme already omits host)

# Disable Fedora bash color prompt influence (not relevant in zsh)
unset bash_color_prompt_disable 2>/dev/null

# Default editor
export EDITOR=vim
export VISUAL=vim

# Colors
export CLICOLOR=1

# Prompt: show last dir component literally (no "~" for home)
PROMPT='%{$fg_bold[green]%}➜ %{$fg_bold[cyan]%}%~ %{$fg_bold[blue]%}$(git_prompt_info)%{$reset_color%} '


# Disk usage / cleanup
alias du1='du -h --max-depth=1 | sort -hr'
alias cleanup='sudo dnf autoremove -y && sudo dnf clean all'
alias disks='ncdu /'



# ---- System / package management ----
alias upd='sudo dnf upgrade --refresh -y && flatpak update -y'
alias updf='sudo dnf upgrade --refresh -y'
alias upff='flatpak update -y'
alias upall='sudo dnf upgrade --refresh -y && flatpak update -y && sudo fwupdmgr update -y 2>/dev/null; true'
alias rmapp='sudo dnf remove -y'
alias rmflat='flatpak uninstall -y'
alias search='dnf search'
alias searchf='flatpak search'
alias inst='sudo dnf install -y'
alias instf='flatpak install -y'
alias lsapp='dnf list installed'
alias lsflat='flatpak list'
alias fwupd='sudo fwupdmgr refresh && sudo fwupdmgr update'
alias sysinfo='fastfetch'
alias reboot='sudo systemctl reboot'
alias poweroff='sudo systemctl poweroff'
alias sleepnow='systemctl suspend'
alias jctl='journalctl -xe'
alias svstat='systemctl status'
alias svstart='sudo systemctl start'
alias svstop='sudo systemctl stop'
alias svrestart='sudo systemctl restart'
alias svcenable='sudo systemctl enable --now'
alias svcdisable='sudo systemctl disable --now'

# System guide
alias guide='cd ~/docs/system-guide && ls'
alias cheats='cat ~/docs/system-guide/README.md'

# kilo
export PATH=/home/ali/.kilo/bin:$PATH


alias z='zellij'

# opencode
export PATH=/home/ali/.opencode/bin:$PATH

# bun completions
[ -s "/home/ali/.bun/_bun" ] && source "/home/ali/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# QODER_DISPATCHER_PATH v1
path=("$HOME/.qoder/entry" ${path:#"$HOME/.qoder/entry"})
export PATH
# END QODER_DISPATCHER_PATH v1

# Dotfiles
alias dotcd='cd ~/dotfiles'
alias dotstatus='git -C ~/dotfiles status'
# Capture live config -> repo, snapshot installed packages, commit, push.
# These lived in ~/.config/fish/aliases.fish, which was dropped with fish.
dotpush() {
  ~/dotfiles/scripts/sync.sh &&
    ~/dotfiles/scripts/backup.sh &&
    git -C ~/dotfiles add -A &&
    git -C ~/dotfiles commit -m "chore: $(date '+%Y-%m-%d %H:%M:%S')" &&
    git -C ~/dotfiles push
}
