set fish_function_path $fish_function_path $HOME/.config/fish/plugin-foreign-env/functions
set PATH $PATH /var/lib/snapd/snap/bin
command -v flutter >/dev/null && set PATH $PATH (flutter sdk-path)/bin

set EDITOR nvim

# Load pyenv only if it is installed on the system
if command -sq pyenv
    status is-login; and pyenv init --path | source
    #pyenv init - | source
end
# set the alias vim
alias vim="nvim"

# Just call `new-project` in your fish terminal to start a new project with the preferred template
alias new-project="~/.config/scripts/new-project"

# Load the starship prompt
command -v starship >/dev/null && starship init fish | source

# set the exa alias
command -v exa >/dev/null && alias ls="exa -la"

# set the cat alias
command -v bat >/dev/null && alias cat="bat"

# set the man pager to bat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

