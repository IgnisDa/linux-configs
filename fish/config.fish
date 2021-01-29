#set fish_function_path $fish_function_path $HOME/.config/fish/plugin-foreign-env/functions
set PATH $PATH /var/lib/snapd/snap/bin
which flutter &>/dev/null && set PATH $PATH (flutter sdk-path)/bin
set PATH $PATH $HOME/.cargo/bin
set EDITOR vim

# Load pyenv only if it is installed on the system
which pyenv &>/dev/null && status --is-interactive; and source (pyenv init -|psub)

# Just call `new-project` in your fish terminal to start a new project with the preferred template
alias new-project="~/.config/scripts/new-project"

# Load the starship prompt
which starship &>/dev/null && starship init fish | source

# set the exa alias
which exa &>/dev/null && alias ls="exa -la"

# set the cat alias
which bat &>/dev/null && alias cat="bat"
