# -- basics
shopt -s globstar 2> /dev/null
PS1='[\u@\h \W]\$ ' 2> /dev/null
setopt PROMPT_SUBST 2> /dev/null
(autoload -U colors && colors) 2> /dev/null
PROMPT='[%{$fg[magenta]%}%n%{$reset_color%}@%{$fg[yellow]%}%m%{$reset_color%}:%~]%(!.#.$) '
# --

# changes zsh autocomplete to work like bash's
setopt noautomenu 2> /dev/null
setopt nomenucomplete 2> /dev/null
###

# variables
ENABLE_LOCALE=false
EXT_MONITOR=HDMI-1
INTERNAL_MONITOR=eDP-1
#

EDITOR=vim
# TERM=terminator
# xdg-settings set default-web-browser chromium.desktop
BROWSER=chromium
export CHROME_EXECUTABLE=chromium

# -- xrandr
fix_res() {
  xrandr --newmode "1600x900_60.00" 118.25 1600 1696 1856 2112 900 903 908 934 -hsync +vsync
  xrandr --addmode VGA1 "1600x900_60.00"
  xrandr --output VGA1 --mode "1600x900_60.00"
}

switch_keys() {
  file='/tmp/_key.config'
  current_key=`cat $file`
  next_key=`if [ "$current_key" == "us" ]; then echo "br"; else echo "us"; fi`
  switch_keys_to $next_key
}

switch_keys_to() {
  file='/tmp/_key.config'
  next_key=$1
  setxkbmap $next_key 2> /dev/null
  echo $next_key > $file
}

function sk() {
  switch_keys_to 'us'
}
sk

# res=2560x1440
res=1920x1080

house_monitor() {
  house_monitor_right
}

house_monitor_up() {
  xrandr --output $EXT_MONITOR --mode $res --above $INTERNAL_MONITOR
}

house_monitor_left() {
  xrandr --output $EXT_MONITOR --mode $res --left-of $INTERNAL_MONITOR
}

house_monitor_right() {
  xrandr --output $EXT_MONITOR --mode $res --right-of $INTERNAL_MONITOR
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

function most_used {
  size=${1:-10}
  history 1 | cat | awk '{CMD[$2]++;count++;} END { for (a in CMD) \
    print CMD[a] " " CMD[a]/count*100 "% " a; }' | grep -v "./" \
    | column -c3 -s " " -t | sort -nr | nl | head -n $size
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
alias fweb='flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true --web-port 5000'
alias fa='flutter run -d emulator-5554'
alias fl='flutter run -d linux'
alias fb='flutter pub run build_runner build'
alias path='realpath'

alias lock='xscreensaver-command -l'
alias lockexit='pma exit && lock'

source ~/projects/dotfiles/fn-git.sh

if [ -n "$ZSH_VERSION" ]; then
  # test -f ~/softwares/scripts/.git-completion.zsh && . $_
  true
else
  test -f ~/softwares/scripts/.git-completion.bash && . $_
fi

alias src='source'
alias vbash='vim ~/.bashrc'
alias vfunc='vim ~/projects/dotfiles/functions.sh'
alias vvim='vim ~/.vimrc'
alias sbash='src ~/.bashrc'

alias mci='mvn clean install'
alias mcint='mci -Dmaven.test.skip'

alias g='./gradlew'
alias gbuild='g build'
alias grun='g bootRun'
alias glint='./tools/hooks/detekt-push-or-commit.sh push'
alias glint-type-resolution='g detektMainWithTypeResolution detektTestWithTypeResolution --max-workers=6'
alias glint-from-scratch='g detekt -x build'
alias gproto='g buildProtos'
alias gios='g buildIosProtos && (c protos ; zip -r ios-protos.zip ios-protos/*)'
alias gios-cleanup='(c protos ; rm -rf ios-protos*)'

alias sus='sudo systemctl suspend'
alias off='sudo halt -p'

alias pac='sudo pacman'
alias up='pac -Syyu'
alias up-aur='yay -Syyu'

alias xc='xclip -selection c'
alias crop='echo "Use imagemagick to crop images; e.g.:"; echo "convert print.png -crop WxH+DX+DY printo.png"'
function myip {
  ip addr | grep -a wlp2s0 | sed -n 2p | rex '^.*inet ([\d.]*).*$' '$1'
}
# --

# -- advanced aliases
alias c='cd'
alias b='cd ..'
alias l='ll'
alias t='tree'
alias v='vim'
alias n='npm'
alias nr='npm run'
alias y='yarn'
alias m='mvn'
alias vr='vim -u NONE'
alias ch='chromium'
alias ff='firefox'
alias bb='cd ../..'
alias bbb='cd ../../..'
alias f='flutter'
alias fpg='f pub get'
alias k='kubectl'
alias pg='ps aux | grep'
# --

# -- path
function add_path_if_exists {
  if [ -d "$1" ]; then
    export PATH="$1:$PATH"
  fi
}

function software {
  add_path_if_exists "$HOME/softwares/$1"
}

software ""
software "scripts"

software 'flutter/flutter/bin'
add_path_if_exists "$HOME/.pub-cache/bin"
software 'google-cloud-sdk/bin'
# software 'dart-sdk/bin'
software 'node-v10.12.0-linux-x64/bin'

android="$HOME/softwares/android/Android"
if [ -d "$android" ]; then
  export ANDROID_HOME="$android"
fi
if [ -d "$HOME/softwares/java" ]; then
  src ~/projects/dotfiles/java.sh
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

src ~/projects/dotfiles/net.sh

alias mount_hhd='sudo mount -o gid=users,uid=1000,umask=0000 /dev/sda2 /mnt/hdd'
alias mount_usb='sudo mount /dev/sdc1 /mnt/pendrive'

alias curlj='curl -H "Content-Type: application/json"'
alias hask=runhaskell
