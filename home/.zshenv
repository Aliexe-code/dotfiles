# zsh environment (sourced for every zsh invocation)
# Make extracted zsh functional without system install
ZSH_HOME="$HOME/tools/zsh/usr"
module_path=("$ZSH_HOME/lib64/zsh/5.9" $module_path)
fpath=("$ZSH_HOME/share/zsh/5.9/functions" "$ZSH_HOME/share/zsh/site-functions" $fpath)

# PATH
export PATH="$HOME/.local/bin:$HOME/tools/v:$HOME/go/bin:/usr/local/go/bin:$PATH"
# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
# V
export V_HOME="$HOME/tools/v"

# QODER_DISPATCHER_PATH v1
path=("$HOME/.qoder/entry" ${path:#"$HOME/.qoder/entry"})
export PATH
# END QODER_DISPATCHER_PATH v1

# ZVM
export ZVM_INSTALL="$HOME/.zvm/self"
if [ -d "$ZVM_INSTALL" ]; then
  export PATH="$PATH:$HOME/.zvm/bin"
  export PATH="$PATH:$ZVM_INSTALL"
fi
