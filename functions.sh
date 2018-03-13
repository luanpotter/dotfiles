# -- basics
shopt -s globstar
PS1='[\u@\h \W]\$ '
# --

# -- xrandr
fix_res() {
  xrandr --newmode "1600x900_60.00" 118.25 1600 1696 1856 2112 900 903 908 934 -hsync +vsync
  xrandr --addmode VGA1 "1600x900_60.00"
  xrandr --output VGA1 --mode "1600x900_60.00"
}

house_monitor() {
  xrandr --output HDMI1 --mode 1920x1080 --right-of LVDS1
}

present() {
  xrandr --output HDMI1 --mode 800x600 --right-of LVDS1
}
# --

# -- basic aliases
alias ls='ls --color=auto'
alias ll='ls -lAh'
alias lll='watch -n 1 ls -lrt'
alias ttt='watch -n 1 tree'
alias nc='ncat'

alias lock='xscreensaver-command -l'
alias lockexit='pma exit && lock'

alias git='hub'
alias gcm='git commit -m '
alias gall='git add -A'
alias gpr='git pull --rebase'

alias src='source'
alias vbash='vim ~/.bashrc'
alias vfunc='vim ~/projects/dotfiles/functions.sh'
alias sbash='src ~/.bashrc'

alias mci='mvn clean install'
alias mcint='mci -Dmaven.test.skip'

alias g='./gradlew build'
alias grun='./gradlew bootRun'

alias chrome='google-chrome-beta'
alias google-chrome='google-chrome-beta'

alias xc='xclip -selection c'
alias crop='echo "Use imagemagick to crop images; e.g.:"; echo "convert print.png -crop WxH+DX+DY printo.png"'
# --

# -- advanced aliases
alias c='cd'
alias b='cd ..'
alias s='git st'
alias d='git diff -w'
alias l='ll'
alias t='tree'
alias v='vim'
# --

# -- path
export PATH="$HOME/softwares/scripts:$HOME/softwares:$PATH"

flutter="$HOME/softwares/flutter/flutter/bin"
if [ -d "$flutter" ]; then
  export PATH="$flutter:$PATH"
fi

android="$HOME/softwares/android/Android"
if [ -d "$android" ]; then
  export ANDROID_HOME="$android"
fi
# --

# -- locale
export KEYMAP="br-abnt2.map.gz"
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
# fix
setxkbmap -model abtn2 -layout br -variant abnt2
# --


src "$(dirname "${BASH_SOURCE[0]}")/net.sh"
