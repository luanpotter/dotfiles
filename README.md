# dotfiles

These are my personal dotfiles, containing some crucial scripts, functions and aliases.

## Structure

All machines are structured as follows, inside your home dir:

```
.
├── .config # basic config folder most programs use, should be there already
├── projects # where you will clone every project
├── softwares # software binaries and scripts (not cloned)
└── downloads # where all software will be configured to put downloads (browsers, torrent, etc)
```

## Setup

Setup is really easy:

 * Copy `.config` files to your config folder:

```bash
    cp -R .config ~/
```

 * Link scripts folder inside your softwares folder:

 ```bash
     mkdir $HOME/softwares
     ln -s $HOME/projects/dotfiles/scripts $HOME/softwares/scripts
 ```

 * Source `functions.sh` in your `.bashrc`; it should look like this:

 ```bash
    # If not running interactively, don't do anything
    [[ $- != *i* ]] && return

    source "$HOME/projects/dotfiles/functions.sh"

    # Env specific custom stuff
    # ...
 ```

 Note: if you are using zsh, don't forget to make sure your `~/.zshrc` is sourcing your bashrc:

 ```bash
   source ~/.bashrc
 ```

 * Use the script to install the custom fonts:

```bash
    cd ./fonts
    ./install.sh
    # must be run from within fonts folder (TODO fix this!)
```

 * Setup git only once in your life (changes are persistent):

```bash
    ./git.sh # open this file first to change your email and name!
```

 * Finally, link the .vimrc file:

 ```bash
     ln -s $HOME/projects/dotfiles/.vimrc ~/.vimrc
```

After that, you must open vim once (`v`), and see a lot of erros; just run `:PlugInstall` once to do everything. Next run should give you no errors.
