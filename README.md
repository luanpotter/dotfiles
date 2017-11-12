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
    cp -R .config $HOME/.config
```

 * Link scripts folder inside your softwares folder:

 ```bash
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