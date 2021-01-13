#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

# Default Programs
#export NMON=cmknt
export EDITOR="nvim"
export PAGER="nvimpager"
# export VISUAL="subl3"
export BROWSER="vivaldi-stable"
export BROWSERCLI="w3m"
export MOVPLAY="mpv"
export PICVIEW="feh"
export SNDPLAY="mpd"
export TERMINAL="st"
export PULSE_LATENCY_MSEC=60

export TERM="xterm-256color"

# File Extensions
for ext in org php com net no;    					do alias -s $ext=$BROWSER; done
for ext in html xhtml xml txt tex py PKGBUILD;      do alias -s $ext=$EDITOR; done
for ext in png jpg gif;                             do alias -s $ext=$PICVIEW; done
for ext in mpg wmv avi mkv;                         do alias -s $ext=$MOVPLAY; done
for ext in wav mp3 ogg;                             do alias -s $ext=$SNDPLAY; done
