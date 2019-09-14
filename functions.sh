# -- basics
shopt -s globstar 2> /dev/null
PS1='[\u@\h \W]\$ '
# --

# variables
ENABLE_LOCALE=false
EXT_MONITOR=HDMI-1-1
INTERNAL_MONITOR=eDP-1-1
#

EDITOR=vim
# TERM=terminator
# xdg-settings set default-web-browser chromium.desktop
BROWSER=chromium

# -- xrandr
fix_res() {
  xrandr --newmode "1600x900_60.00" 118.25 1600 1696 1856 2112 900 903 908 934 -hsync +vsync
  xrandr --addmode VGA1 "1600x900_60.00"
  xrandr --output VGA1 --mode "1600x900_60.00"
}

house_monitor() {
  house_monitor_right
}

house_monitor_up() {
  xrandr --output $EXT_MONITOR --mode 1920x1080 --above $INTERNAL_MONITOR
}

house_monitor_left() {
  xrandr --output $EXT_MONITOR --mode 1920x1080 --left-of $INTERNAL_MONITOR
}

house_monitor_right() {
  xrandr --output $EXT_MONITOR --mode 1920x1080 --right-of $INTERNAL_MONITOR
}

present() {
  xrandr --output $EXT_MONITOR --mode 800x600 --right-of $INTERNAL_MONITOR
}

mirror() {
  xrandr --output $INTERNAL_MONITOR --mode 800x600
  xrandr --output $EXT_MONITOR --mode 800x600 --same-as $INTERNAL_MONITOR
}

clear_screen() {
  xrandr --output $INTERNAL_MONITOR --mode 1920x1080
}

removeFromPath() {
   local p d
   p=":$1:"
   d=":$PATH:"
   d=${d//$p/:}
   d=${d/#:/}
   PATH=${d/%:/}
}
# --

## -- mk projects aliases
alias mkp-java8='to_java8 && m archetype:generate -DarchetypeGroupId=xyz.luan.generator -DarchetypeArtifactId=xyz-generator -DarchetypeVersion=0.3.0'
alias mkp-java11='to_java11 && m archetype:generate -DarchetypeGroupId=xyz.luan.generator -DarchetypeArtifactId=xyz-generator -DarchetypeVersion=0.3.0 -Djava-version=11'
alias mkp-js='n init'
## --

# colored ls on all systems
export CLICOLOR=1
ls --color=auto &> /dev/null && alias ls='ls --color=auto'
#

# -- basic aliases
alias ll='ls -lAh'
alias lll='watch -n 1 ls -lrt'
alias ttt='watch -n 1 tree'
alias nc='ncat'
alias tailf='tail -f'

# pma - old pma stuff
# alias pma-log='vim ~/projects/dextra/pma/dist/log.dat'
# alias pma='~/projects/dextra/pma/cmds/run.sh'
#

alias dry-run='flutter packages pub publish --dry-run'
alias flutter-publish='flutter packages pub publish'
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
alias vvim='vim ~/.vimrc'
alias sbash='src ~/.bashrc'

alias mci='mvn clean install'
alias mcint='mci -Dmaven.test.skip'

alias g='./gradlew build'
alias grun='./gradlew bootRun'

alias sus='sudo systemctl suspend'
alias off='sudo halt -p'

alias pintas='scrot -d 1 -u /tmp/temp.scrot.png && pinta /tmp/temp.scrot.png && rm /tmp/temp.scrot.png'

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
alias n='npm'
alias nr='npm run'
alias m='mvn'
alias vr='vim -u NONE'
alias ch='chromium'
alias bb='cd ../..'
alias f='flutter'
alias fpg='f pub get'
# --

alias xxx="gall && gcm '.' && git push"

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
if [ "$ENABLE_LOCALE" = "true" ]; then
  export KEYMAP="br-abnt2.map.gz"
  export LANG=en_US.UTF-8
  export LC_CTYPE=en_US.UTF-8
  # fix
  setxkbmap -model abtn2 -layout br -variant abnt2
fi
# --

src "$(dirname "${BASH_SOURCE[0]}")/net.sh"
src "$(dirname "${BASH_SOURCE[0]}")/java.sh"

alias curlj='curl -H "Content-Type: application/json"'
