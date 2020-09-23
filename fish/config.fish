set fish_function_path $fish_function_path $HOME/.config/fish/plugin-foreign-env/functions

status --is-interactive; and source (pyenv init -|psub)
source ~/.asdf/asdf.fish
