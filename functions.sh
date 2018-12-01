# -- basics
shopt -s globstar
PS1='[\u@\h \W]\$ '
# --

EDITOR=vim
TERM=terminator

# xdg-settings set default-web-browser chromium.desktop
BROWSER=chromium

# -- xrandr
fix_res() {
  xrandr --newmode "1600x900_60.00" 118.25 1600 1696 1856 2112 900 903 908 934 -hsync +vsync
  xrandr --addmode VGA1 "1600x900_60.00"
  xrandr --output VGA1 --mode "1600x900_60.00"
}

house_monitor() {
  xrandr --output HDMI-1 --mode 1920x1080 --right-of eDP-1
}

present() {
  xrandr --output HDMI-1 --mode 800x600 --right-of eDP-1
}
# --

# -- basic aliases
alias ls='ls --color=auto'
alias ll='ls -lAh'
alias lll='watch -n 1 ls -lrt'
alias ttt='watch -n 1 tree'
alias nc='ncat'
alias tailf='tail -f'

alias path='realpath'

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

alias xc='xclip -selection c'
alias crop='echo "Use imagemagick to crop images; e.g.:"; echo "convert print.png -crop WxH+DX+DY printo.png"'
function myip {
  ip addr | grep -a wlp2s0 | sed -n 2p | rex '^.*inet ([\d.]*).*$' '$1'
}
# --

# -- advanced aliases
alias c='cd'
alias b='cd ..'
alias s='git status'
alias d='git diff -w'
alias l='ll'
alias t='tree'
alias v='vim'
alias vr='vim -u NONE'
alias ch='chromium'
# --

# -- path
export PATH="$HOME/softwares/scripts:$HOME/softwares:$PATH"

function add_path_if_exists {
  if [ -d "$1" ]; then
    export PATH="$1:$PATH"
  fi
}

function software {
  add_path_if_exists "$HOME/softwares/$1"
}

software 'flutter/flutter/bin'
software 'google-cloud-sdk/bin'
software 'dart-sdk/bin'
software 'node-v10.12.0-linux-x64/bin'

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

alias curlj='curl -H "Content-Type: application/json"'
