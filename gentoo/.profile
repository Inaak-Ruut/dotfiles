# Export important locations

export XDG_DATA_HOME=${XDG_DATA_HOME:="$HOME/.local/share"}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:="$HOME/.cache"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:="$HOME/.config"}
export HISTFILE="$XDG_DATA_HOME"/shell/common/history
export GTK2_RC_FILES="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-2.0/gtkrc-2.0"
export PATH="$HOME/.scripts:$(ruby -e 'puts Gem.user_dir')/bin"

# Export Gentoo optimisation options

export NUMCPUS=$(nproc)
export NUMCPUSPLUSONE=$(( NUMCPUS + 1 ))
export MAKEOPTS="-j${NUMCPUSPLUSONE} -l${NUMCPUS}"
export EMERGE_DEFAULT_OPTS="--jobs=${NUMCPUSPLUSONE} --load-average=${NUMCPUS}"

# If the system language is not set, then set it to Polish (UTF-8)

if [[ $LANG = '' ]]; then
  export LANG=pl_PL.UTF-8
fi

# Load .bashrc

[[ -f ${XDG_CONFIG_HOME:-$HOME/.config}/shell/.bashrc ]] && . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/.bashrc

# Export default software

export EDITOR="nvim"
export READER="zathura"
export VISUAL="nvim"
#export CODEEDITOR="vscodium"
export TERMINAL="st"
export BROWSER="vivaldi-stable"
export COLORTERM="truecolor"
export PAGER="nvimpager"
export WM="i3-gaps"
# export RANGER_LOAD_DEFAULT_RC=FALSE

if [[ "$(tty)" = "/dev/tty1" ]]; then
	pgrep i3-gaps || startx "${XDG_CONFIG_HOME:-$HOME/.config}/X11/xinitrc"
fi
