#
# ~/.bashrc
#

# Gentoo options for a more reasonable CPU load during emerge

# export NUMCPUS=$(nproc)
# export NUMCPUSPLUSONE=$(( NUMCPUS + 1 ))
# export MAKEOPTS="-j${NUMCPUSPLUSONE} -l${NUMCPUS}"
# export EMERGE_DEFAULT_OPTS="--jobs=${NUMCPUSPLUSONE} --load-average=${NUMCPUS}"

[[ $- != *i* ]] && return
[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases" # Load command aliases
[ -f "$HOME/.bash_shortcuts" ] && source "$HOME/.bash_shortcuts" # Load shortcut aliases

#If the system language is not set, then set it to Polish (UTF-8)

if [[ $LANG = '' ]]; then
  export LANG=pl_PL.UTF-8
fi

PS1='\n[\u@\h]: \w\n$?> '

# exec "setxkbmap -option caps:super"

# Set CapsLock as the Mod key (in dwm and i3)
# xmodmap -e "remove Lock = Caps_Lock"
# xmodmap -e "clear mod2"
# xmodmap -e "add Mod2 = Caps_Lock"

colors() {
	local fgc bgc vals seq0

	printf "Color escapes are %s\n" '\e[${value};...;${value}m'
	printf "Values 30..37 are \e[33mforeground colors\e[m\n"
	printf "Values 40..47 are \e[43mbackground colors\e[m\n"
	printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

	# foreground colors
	for fgc in {30..37}; do
		# background colors
		for bgc in {40..47}; do
			fgc=${fgc#37} # white
			bgc=${bgc#40} # black

			vals="${fgc:+$fgc;}${bgc}"
			vals=${vals%%;}

			seq0="${vals:+\e[${vals}m}"
			printf "  %-9s" "${seq0:-(default)}"
			printf " ${seq0}TEXT\e[m"
			printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
		done
		echo; echo
	done
}

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

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

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.

safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.gruvbox.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.gruvbox.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
	&& type -P dircolors >/dev/null \
	&& match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
	# Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
	c ; then
		if [[ -f ~/.config/colours/.gruvbox.dir_colors ]] ; then
			eval $(dircolors -b ~/.config/colours/.gruvbox.dir_colors)
		elif [[ -f ~/.config/colours/.nord.dir_colors ]] ; then
			eval $(dircolors -b ~/.config/colours/.nord.dir_colors)
		elif [[ -f /etc/DIR_COLORS ]] ; then
			eval $(dircolors -b /etc/DIR_COLORS)
		fi
fi

	if [[ ${EUID} == 0 ]] ; then
		PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
	else
		PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
	fi


else
	if [[ ${EUID} == 0 ]] ; then
		# show root@ when we don't have colors
		PS1='\u@\h \W \$ '
	else
		PS1='\u@\h \w \$ '
	fi
fi

unset use_color safe_term match_lhs sh

alias cp="cp -i"                          # confirm before overwriting something
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias more=less

# make less more friendly for non-text input files, see lesspipe(1)                                                                                                       
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Color for manpages in less makes manpages a little easier to read:

export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

xhost +local:root > /dev/null 2>&1

complete -cf sudo

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
shopt -s checkwinsize
shopt -s expand_aliases

# export QT_SELECT=4

# Enable history appending instead of overwriting.  #139609
shopt -s histappend

# copy and go to dir
cpg (){
  if [ -d "$2" ];then
    cp $1 $2 && cd $2
  else
    cp $1 $2
  fi
}

# move and go to dir
mvg (){
  if [ -d "$2" ];then
    mv $1 $2 && cd $2
  else
    mv $1 $2
  fi
}

# Makes directory then moves into it
#function mkcdr {
mkcdr () {
    mkdir -p -v $1
    cd $1
}

# # ex - archive extractor
# # usage: ex <file>
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Lets you set reminders to display whenever you open a new terminal. 
# Everything in ~/.reminder will be displayed. 
# Everything in ~/.reminder-oneshot will be displayed and then the file will be erased. 

if [ -f $HOME/.reminder ]; then
    cat $HOME/.reminder
fi

if [ -f $HOME/.reminder-oneshot ]; then
    cat $HOME/.reminder-oneshot
    rm $HOME/.reminder-oneshot
fi

# Use remind whatever to add a new line to ~/.reminder, or remind with no arguments to run it interactively 
# and add multiple lines. Use unremind to remove the last line from ~/.reminder 
# (this requires moreutils to be installed).

remind() {
    if [ "$1" ]; then
        echo "$@" >> ~/.reminder
    else
        cat >> ~/.reminder
    fi
}

alias unremind='head -n-1 ~/.reminder | sponge ~/.reminder'