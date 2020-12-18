#
# ~/.bash_aliases
#

# Various administration aliases

alias ls="ls -laH --color=auto --group-directories-first"
# alias ranger="ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR""
alias reload="source ~/.bashrc"
alias ranger='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'
alias orphans='yay -Rns $(pacman -Qtdq)'
alias update='sudo pacman-mirrors --fasttrack && yay -Syyu'

# Various navigation aliases

alias epub="cd /home/przemio/MEGA/MEGAsync/epub/ && ls -laH"
alias litir="cd /home/przemio/MEGA/MEGAsync/epub/Celtic/Gaelic/Litir/ && ls"
alias home="cd /home/przemio/"

# Useful temporary edit aliases

alias vimrc="nvim ~/.config/nvim/init.vim"
alias bashrc="nvim ~/.bashrc"
alias rom="nvim /home/przemio/MEGA/MEGAsync/epub/Romance/Rumuński/rom.xhtml"
