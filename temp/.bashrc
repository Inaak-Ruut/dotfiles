#
# ~/.bashrc
#

# Gentoo options for a more reasonable CPU load during emerge

# export NUMCPUS=$(nproc)
# export NUMCPUSPLUSONE=$(( NUMCPUS + 1 ))
# export MAKEOPTS="-j${NUMCPUSPLUSONE} -l${NUMCPUS}"
# export EMERGE_DEFAULT_OPTS="--jobs=${NUMCPUSPLUSONE} --load-average=${NUMCPUS}"

[[ $- != *i* ]] && return

# Source configs
for f in $XDG_DATA_HOME/shell/common/*; do source "$f"; done

# Starship Prompt
eval "$(starship init bash)"

# Load bash-completion

[ -r $XDG_DATA_HOME/shell/common/bash/bash-completion/bash_completion ] && . $XDG_DATA_HOME/shell/common/bash/bash-completion/bash_completion

PS1='\n[\u@\h]: \w\n$?> '

# exec "setxkbmap -option caps:super"

# Set CapsLock as the Mod key (in dwm and i3)
# xmodmap -e "remove Lock = Caps_Lock"
# xmodmap -e "clear mod2"
# xmodmap -e "add Mod2 = Caps_Lock"

# make less more friendly for non-text input files, see lesspipe(1)                                                                                                       
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Change the window title of X terminals

case ${TERM} in
	xterm*|rxvt*|Eterm*|aterm|kterm|gnome*|interix|konsole*)
		PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'
		;;
	screen*)
		PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\033\\"'
		;;
esac

use_color=true

# Color for manpages in less makes manpages a little easier to read:

# export LESS_TERMCAP_mb=$'\E[01;31m'
# export LESS_TERMCAP_md=$'\E[01;31m'
# export LESS_TERMCAP_me=$'\E[0m'
# export LESS_TERMCAP_se=$'\E[0m'
# export LESS_TERMCAP_so=$'\E[01;44;33m'
# export LESS_TERMCAP_ue=$'\E[0m'
# export LESS_TERMCAP_us=$'\E[01;32m'

xhost +local:root > /dev/null 2>&1

complete -cf sudo

