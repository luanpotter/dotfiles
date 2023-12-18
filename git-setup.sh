# install git and hub, something like
# sudo pacman -S git hub
# dont forget to add your ssh key too; check:
# https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

git config --global rerere.enabled true
git config --global pull.rebase true
git config --global advice.skippedCherryPicks false
git config --global branch.main.pushRemote NOPE
git config --global pile.cleanupRemoteOnSubmitFailure true
git config --global push.autoSetupRemote true

git config --global user.email "luanpotter27@gmail.com"
git config --global user.name "Luan Nico"

git config --global alias.st status
git config --global alias.br branch
git config --global alias.co checkout
git config --global alias.pushf "push --force-with-lease"
git config --global alias.gone-br "!git fetch -p; git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == \"[gone]\" {sub(\"refs/heads/\", \"\", $1); print $1}' | xargs git br -D"

git config --global push.default current
