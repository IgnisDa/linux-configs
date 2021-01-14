#set fish_function_path $fish_function_path $HOME/.config/fish/plugin-foreign-env/functions
set PATH $PATH /var/lib/snapd/snap/bin
set PATH $PATH (flutter sdk-path)/bin
set PATH $PATH $HOME/.cargo/bin
set EDITOR vim

# Load pyenv only if it is installed on the system
if command pyenv -v >/dev/null
    status --is-interactive; and source (pyenv init -|psub)
end

# Just call `new-project` in your fish terminal to start a new project with the preferred template
alias new-project="cookiecutter https://github.com/IgnisDa/project-cookiecutter.git --directory=\"django-nuxt-docusaurus\""

# Load the starship prompt
starship init fish | source
