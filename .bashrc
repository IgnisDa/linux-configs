#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# if this file is found, it means that we have rust installed to our system
if [ -f $HOME/.cargo/env ]; then
    # this file appends the rust bin directory to $PATH
    source $HOME/.cargo/env
fi

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# activate the fish shell if running interactively
# can be bypassed by executing `bash --norc`
if [[ $(ps --no-header --pid=$PPID --format=cmd) != "fish" ]]
then
	exec fish
fi
. "$HOME/.cargo/env"
