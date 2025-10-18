# -- determine OS
platform=linux
if [[ "$OSTYPE" == "darwin"* ]]; then
  platform=macos
fi
# --

# -- basics
shopt -s globstar 2> /dev/null
PS1='[\u@\h \W]\$ ' 2> /dev/null
setopt PROMPT_SUBST 2> /dev/null
(autoload -U colors && colors) 2> /dev/null
PROMPT='[%{$fg[magenta]%}%n%{$reset_color%}@%{$fg[yellow]%}%m%{$reset_color%}:%~]%(!.#.$) '

# zsh settings
if [ -n "$ZSH_VERSION" ]; then
  # changes zsh autocomplete to work like bash's
  setopt noautomenu
  setopt nomenucomplete
fi
# --

# -- default softwares
EDITOR=vim
if [[ "$platform" == "linux" ]]; then
  TERM=alacritty
fi
export XDG_CONFIG_HOME="$HOME/.config"
BROWSER=firefox
if [[ "$platform" == "linux" ]]; then
  xdg-settings set default-web-browser firefox.desktop
fi
export GTK_THEME=Adwaita-dark
# --

# TODO(luan): re-consider this option
# setxkbmap -option compose:ralt

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

alias dry-run='flutter packages pub publish --dry-run'
alias flutter-publish='flutter packages pub publish'
alias fweb='flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true --web-port 5000'
alias fa='flutter run -d emulator-5554'
alias fl='flutter run -d linux'
alias fb='flutter pub run build_runner build'
alias path='realpath'
alias kts='kotlinc -script'

alias lock='xscreensaver-command -l'
alias lockexit='pma exit && lock'

source ~/projects/dotfiles/fn-git.sh
source ~/projects/dotfiles/monitors.sh

if [ -n "$ZSH_VERSION" ]; then
  # test -f ~/softwares/scripts/.git-completion.zsh && . $_
  true
else
  test -f ~/softwares/scripts/.git-completion.bash && . $_
fi

alias src='source'
alias vbash='v ~/.bashrc'
alias vzsh='v ~/.zshrc'
alias vfunc='v ~/projects/dotfiles/functions.sh'
alias vgit='v ~/projects/dotfiles/fn-git.sh'
alias vmonitors='v ~/projects/dotfiles/monitors.sh'
alias vvim='v ~/.vimrc'
alias vrc='v ~/.config/awesome/rc.lua'
alias vterm='v ~/.config/alacritty/alacritty.yml'
alias sb='src ~/.bashrc'
alias sz='src ~/.zshrc'

alias mci='mvn clean install'
alias mcint='mci -Dmaven.test.skip'

alias g='./gradlew'
alias gbuild='g build'
alias grun='g bootRun'
alias glint='g detekt --auto-correct'
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

function my_ip {
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
alias br='bun run'
alias y='yarn'
alias ylint='yarn nx run-many -t type_checker'
alias m='mvn'
alias vr='vim -u NONE'
alias ch='chromium'
alias ff='firefox'
alias bb='cd ../..'
alias bbb='cd ../../..'
alias bbbb='cd ../../../..'
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
  add_path_if_exists "$HOME/bin/$1"
}

software ""
software "scripts"
software "local_scripts"

add_path_if_exists "$HOME/.yarn/bin"
add_path_if_exists "$HOME/.pub-cache/bin"
add_path_if_exists "$HOME/.bun/bin"

software 'flutter/bin'
software 'google-cloud-sdk/bin'
software 'node-v10.12.0-linux-x64/bin'

android="$HOME/softwares/android/Android"
if [ -d "$android" ]; then
  export ANDROID_HOME="$android"
fi
if [ -d "$HOME/softwares/java" ]; then
  src ~/projects/dotfiles/java.sh
fi
# --

src ~/projects/dotfiles/net.sh

alias mount_hhd='sudo mount -o gid=users,uid=1000,umask=0000 /dev/sda2 /mnt/hdd'
alias mount_usb='sudo mount /dev/sdc1 /mnt/pendrive'

alias curlj='curl -H "Content-Type: application/json"'
alias hask=runhaskell

function to_mp3 {
  ffmpeg -i "$1" -vn -ab 128k -ar 44100 -y "$2"
}

function download_mp3 {
  yt-dlp "$1" -o "video.webm"
  mv "video.webm.mp4" "video.webm"
  to_mp3 "video.webm" "$2"
  rm "video.webm"
}
