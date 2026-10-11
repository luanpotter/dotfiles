#!/usr/bin/env bash
# -- determine OS
platform=linux
if [[ "$OSTYPE" == "darwin"* ]]; then
	platform=macos
fi
# --

# -- basics
shopt -s globstar 2>/dev/null
PS1='[\u@\h \W]\$ ' 2>/dev/null
setopt PROMPT_SUBST 2>/dev/null
(autoload -U colors && colors) 2>/dev/null
export PROMPT="[%{\$fg[magenta]%}%n%{\$reset_color%}@%{\$fg[yellow]%}%m%{\$reset_color%}:%~]%(!.#.$) "

# -- zsh settings
if [ -n "$ZSH_VERSION" ]; then
	# changes zsh autocomplete to work like bash's
	setopt noautomenu
	setopt nomenucomplete

	# restore reverse search (vi mode overrides this)
	bindkey '^R' history-incremental-search-backward

	# word movement and line start/end while typing. EDITOR=vim puts zsh in
	# the vi keymap, where these are unbound (ctrl+a even inserts a literal
	# ^A) and ctrl+arrows would fall through to normal mode. covers the
	# ctrl+arrow, alt+arrow and "esc b"/"esc f" encodings terminals send.
	for keymap in viins vicmd emacs; do
		bindkey -M "$keymap" '^[[1;5D' backward-word
		bindkey -M "$keymap" '^[[1;5C' forward-word
		bindkey -M "$keymap" '^[[1;3D' backward-word
		bindkey -M "$keymap" '^[[1;3C' forward-word
		# home/end as sent by ghostty directly and as tmux re-encodes them
		bindkey -M "$keymap" '^[[H' beginning-of-line
		bindkey -M "$keymap" '^[[F' end-of-line
		bindkey -M "$keymap" '^[[1~' beginning-of-line
		bindkey -M "$keymap" '^[[4~' end-of-line
	done
	bindkey -M viins '^[b' backward-word
	bindkey -M viins '^[f' forward-word
	bindkey -M viins '^A' beginning-of-line
	bindkey -M viins '^E' end-of-line
	bindkey -M viins '^[^?' backward-kill-word
	# vi mode's ^U only kills what was typed since entering insert mode
	bindkey -M viins '^U' backward-kill-line
	unset keymap
fi
# --

# -- default softwares
export EDITOR=vim

if [[ "$platform" == "linux" ]]; then
	TERM="xterm-256color"
fi

export XDG_CONFIG_HOME="$HOME/.config"
export BROWSER=firefox
export GTK_THEME=Adwaita-dark

# TODO(luan): re-consider this option
# setxkbmap -option compose:ralt

# --

# -- helper functions
maybe_unalias() {
	local name="$1"
	if alias "$name" 2>/dev/null; then
		unalias "$name"
	fi
}

remove_from_path() {
	local p d
	p=":$1:"
	d=":$PATH:"
	d=${d//$p/:}
	d=${d/#:/}
	PATH=${d/%:/}
}

most_used() {
	local size=${1:-10}
	history 1 | awk '
		{ cmd[$2]++; total++ }
		END { for (c in cmd) print cmd[c], cmd[c]/total*100 "%", c }
	' | grep -v "./" | column -c3 -s ' ' -t | sort -nr | nl | head -n "$size"
}

to_mp3() {
	ffmpeg -i "$1" -vn -ab 128k -ar 44100 -y "$2"
}

download_mp3() {
	yt-dlp "$1" -o "video.webm"
	mv "video.webm.mp4" "video.webm"
	to_mp3 "video.webm" "$2"
	rm "video.webm"
}

xc() {
	if [[ "$platform" == "linux" ]]; then
		wl-copy -n -t text/plain
	else
		pbcopy
	fi
}
# --

# colored ls on all systems
export CLICOLOR=1
ls --color=auto &>/dev/null && alias ls='ls --color=auto'
#

# -- basic aliases
alias ll='ls -lAh'
alias lll='watch -n 1 ls -lrt'
alias ttt='watch -n 1 tree'
alias nc='ncat'
alias tailf='tail -f'

alias flutter-dry-run='flutter packages pub publish --dry-run'
alias flutter-publish='flutter packages pub publish'
alias fweb='flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true --web-port 5000'
alias fa='flutter run -d emulator-5554'
alias fl='flutter run -d linux'
alias fb='flutter pub run build_runner build'

alias path='realpath'
alias kts='kotlinc -script'

# TODO: reconsider these
alias sus='sudo systemctl suspend'
alias off='sudo halt -p'

alias src='source'
alias sb='src ~/.bashrc'
alias sz='src ~/.zshrc'
alias vbash='v ~/.bashrc'
alias vzsh='v ~/.zshrc'
alias vfunc='v ~/projects/dotfiles/functions.sh'
alias vgit='v ~/projects/dotfiles/inc/fn-git.sh'
alias vvim='v ~/.vimrc'
alias vway='v ~/.config/hypr/hyprland.lua'
alias vterm='v ~/.config/ghostty/config'

alias mci='mvn clean install'
alias mcint='mci -Dmaven.test.skip'

alias g='./gradlew'
alias gbuild='g build'
alias grun='g bootRun'
alias glint='g detekt --auto-correct'
alias gproto='g buildProtos'

alias pac='sudo pacman'
alias up='~/projects/dotfiles/update.sh'
alias up-pac='pac -Syyu'
alias prune='pac -Qqdt | pac -Rsn -'

alias crop='echo "Use imagemagick to crop images; e.g.:"; echo "convert print.png -crop WxH+DX+DY printo.png"'

alias mount_hhd='sudo mount -o gid=users,uid=1000,umask=0000 /dev/sda2 /mnt/hdd'
alias mount_usb='sudo mount /dev/sdc1 /mnt/pendrive'

alias curlj='curl -H "Content-Type: application/json"'
alias hask=runhaskell
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
add_path_if_exists() {
	if [ -d "$1" ]; then
		export PATH="$1:$PATH"
	fi
}

add_software() {
	add_path_if_exists "$HOME/bin/$1"
}

add_software ""
add_software "scripts"
add_software "local_scripts"

add_path_if_exists "$HOME/.yarn/bin"
add_path_if_exists "$HOME/.pub-cache/bin"
add_path_if_exists "$HOME/.bun/bin"
add_path_if_exists "$HOME/.local/bin"
add_path_if_exists "$HOME/.cache/.bun/bin"

# ruby and gems
if [[ "$platform" == "linux" ]]; then
	if command -v gem &>/dev/null; then
		GEM_HOME="$(gem env user_gemhome)"
		export GEM_HOME
		add_path_if_exists "$GEM_HOME/bin"
	fi
fi

add_software 'flutter/bin'
add_software 'google-cloud-sdk/bin'

android="$HOME/softwares/android/Android"
if [ -d "$android" ]; then
	export ANDROID_HOME="$android"
fi
if [ -d "$HOME/softwares/java" ]; then
	src ~/projects/dotfiles/inc/java.sh
fi
# --

# -- nvm
if [[ -f /usr/share/nvm/init-nvm.sh ]]; then
	src /usr/share/nvm/init-nvm.sh
fi
# --

# -- history
export HISTSIZE=100000
export HISTFILESIZE=100000
export SAVEHIST=100000

if [ -n "$ZSH_VERSION" ]; then
	setopt SHARE_HISTORY
	setopt APPEND_HISTORY
	setopt INC_APPEND_HISTORY
elif [ -n "$BASH_VERSION" ]; then
	shopt -s histappend
	export PROMPT_COMMAND="history -a; history -r; $PROMPT_COMMAND"
fi
# --

# -- tmux cwd
# report the shell's cwd to tmux (OSC 7) at each prompt, so ctrl+t opens new
# tabs there instead of wherever a running script has cd'ed into
if [ -n "$TMUX" ]; then
	_tmux_report_cwd() { printf '\e]7;%s\a' "$PWD"; }
	if [ -n "$ZSH_VERSION" ]; then
		precmd_functions+=(_tmux_report_cwd)
	elif [ -n "$BASH_VERSION" ]; then
		export PROMPT_COMMAND="_tmux_report_cwd; $PROMPT_COMMAND"
	fi
fi
# --

# -- imports
src ~/projects/dotfiles/inc/fn-git.sh
if [[ "$platform" == "macos" ]]; then
	src ~/projects/dotfiles/inc/sed-fix.sh
fi
# --
