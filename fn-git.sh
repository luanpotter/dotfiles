# note: this require some aliases defined on the git-setup.sh file

export GIT_PILE_PREFIX="luan."
export GIT_PILE_USE_PR_TEMPLATE=true

# new git pile aliases
alias u='git fetch origin main && git rebase origin/main'
alias spr='git submitpr'
alias upr='git updatepr'

alias gcm='git commit -m '
alias gcma='git commit -m "Address comments"'
alias gac='gall && gcma && git push'
alias grc='git rebase --continue'
alias grs='git rebase --skip'
alias gra='git rebase --abort'
alias gcb='git co -b'
alias gca='git commit --amend --no-edit'
alias ga='git add'
alias gall='git add -A'
alias gpr='git pull --rebase'
alias gpf='git pushf' # pushf is aliased to force with lease
alias gg='git co green && gpr'
alias gm='git co main && gpr'
alias grg='git rebase green'
alias grm='git rebase main'
alias gsf='git stash push '

alias s='git status'
alias d='git diff -w'
alias xxx="gall && gcm '.' && git push"

alias branch='git rev-parse --abbrev-ref HEAD'
function gpu() {
  b=`branch`
  git pull --rebase origin "$b"
}

alias gitb='git --no-pager branch --sort=-committerdate'
function gb() {
  gbb 15 $1
}

function gbb() {
  param=$2
  n=$1
  if [ -z "$param" ]; then
    result=`gitb | head -n$n | awk '{ print "(" NR  ") " $0 }'`
    echo "$result"
  else
    branch=`gitb | awk "NR==$param" | sed 's/[ *]*//g'`
    git checkout "$branch"
  fi
}
