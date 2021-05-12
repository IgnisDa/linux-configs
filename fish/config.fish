set fish_function_path $fish_function_path $HOME/.config/fish/plugin-foreign-env/functions
set PATH $PATH /var/lib/snapd/snap/bin
command -v flutter >/dev/null && set PATH $PATH (flutter sdk-path)/bin

set EDITOR nvim

# Load pyenv only if it is installed on the system
which pyenv &>/dev/null && status --is-interactive; and source (pyenv init -|psub)

# set the alias vim
alias vim="nvim"

# Just call `new-project` in your fish terminal to start a new project with the preferred template
alias new-project="~/.config/scripts/new-project"

# Load the starship prompt
which starship &>/dev/null && starship init fish | source

# set the exa alias
which exa &>/dev/null && alias ls="exa -la"

# set the cat alias
which bat &>/dev/null && alias cat="bat"

# set the man pager to bat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

