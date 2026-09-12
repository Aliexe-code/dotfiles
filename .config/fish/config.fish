source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# aliases (custom, see file)
source ~/.config/fish/aliases.fish

# opencode
fish_add_path /home/ali/.opencode/bin

# kilo
fish_add_path /home/ali/.kilo/bin

# Qwen Code PATH block begin
set -gx PATH '/home/ali/.local/bin' $PATH
# Qwen Code PATH block end

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<


# Added by Antigravity CLI installer
set -gx PATH "/home/ali/.local/bin" $PATH
set -gx PATH $HOME/.npm-global/bin $PATH
set -gx PATH $HOME/go/bin $PATH

# V programming language
fish_add_path $HOME/.local/share/v
# Release tarball ships Windows tcc.exe; use system gcc
set -gx VFLAGS '-cc gcc'
