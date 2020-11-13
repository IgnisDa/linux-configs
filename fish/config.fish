set fish_function_path $fish_function_path $HOME/.config/fish/plugin-foreign-env/functions
set PATH "$PATH:/var/lib/snapd/snap/bin"
set EDITOR vim

# Load pyenv only if it is installed on the system
if command pyenv -v > /dev/null
	status --is-interactive; and source (pyenv init -|psub)
end
