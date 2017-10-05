shopt -s globstar

fix_res() {
  xrandr --newmode "1600x900_60.00" 118.25 1600 1696 1856 2112 900 903 908 934 -hsync +vsync
  xrandr --addmode VGA1 "1600x900_60.00"
  xrandr --output VGA1 --mode "1600x900_60.00"
}

alias src='source'
alias chrome='google-chrome-beta'
alias google-chrome='google-chrome-beta'

alias lock='xscreensaver-command -l'
alias lockexit='pma exit && lock'

alias ll='ls -lA --color=auto'
alias lll='watch -n 1 ls -lrt'
alias xc='xclip -selection c'
alias gcm='git commit -m '
alias gall='git add -A'
alias vbash='vim ~/.bashrc'
alias sbash='src ~/.bashrc'
alias mci='mvn clean install'
alias mcint='mci -Dmaven.test.skip'

export PATH="/home/luan/softwares:$PATH"

#locale
export KEYMAP="br-abnt2.map.gz"
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
