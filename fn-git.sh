# NOTE: this require some aliases defined on the git-setup.sh file

if [ -n "$ZSH_VERSION" ]; then
  # TODO: reconsider this, at some point it was causing issues
  # test -f ~/softwares/scripts/.git-completion.zsh && . $_
  true
else
  test -f ~/softwares/scripts/.git-completion.bash && . $_
fi

alias gcm='git commit -m '
alias gcmnv='git commit --no-verify -m'
alias gcma='gcm "Address comments"'
alias gcmnva='gcmnv "Address comments"'
alias gac='gall && gcma && git push'
alias xxx="gall && gcm '.' && git push"
alias grc='git rebase --continue'
alias grs='git rebase --skip'
alias gra='git rebase --abort'
alias gcb='git co -b'
alias gca='git commit --amend --no-edit'
alias ga='git add'
alias gall='git add -A'
alias gpr='git pull --rebase'
alias gpf='git pushf' # NOTE: pushf is already aliased to force with lease
alias gg='git co green && gpr'
alias gm='git co main && gpr'
alias grg='git rebase green'
alias grm='git rebase main'
alias gsp='git stash pop'
alias gsf='git stash push '
alias gsu='git stash --keep-index'

alias s='git status'
alias d='git diff -w'

alias branch='git rev-parse --abbrev-ref HEAD'
function gpu() {
  b=`branch`
  git pull --rebase origin "$b"
}

alias gitb='git --no-pager branch --sort=-committerdate'
maybe_unalias gb # with zsh, oh-my-zsh might have this pre-bound
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

# graphite
function og_gt() {
  command gt "$@"
}

function gt() {
  if [[ "$1" == "ms" ]]; then
    shift
    command gt s "$@"
  else
    command gt "$@"
  fi
}

alias gtt='gt co `gt trunk`'
alias gts='gtt && gt sync'
alias gms='gall && gt modify && gt s'
alias gmss='gall && gt modify && gt ss'
alias gs='og_gt s -p --cli --no-edit'
alias gsd='gs && gh pr edit --add-label "do-not-request-reviewers"'
