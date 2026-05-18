# dotfiles

These are my personal dotfiles, containing some crucial scripts, functions and aliases.

## Structure

All machines are structured as follows, inside your home dir:

```
.
├── .config # basic config folder most programs use, should be there already
├── projects # where you will clone every project
├── bin # software binaries and scripts (not cloned)
└── downloads # where all software will be configured to put downloads (browsers, torrent, etc)
```

## Setup

Setup is really easy:

 * Run the main update script:

```bash
    ./update.sh
```

It should bootstrap everything for your system!

Note that to finalize the vim install, you must open it once (`v`); you will see a lot of errors, just run `:PlugInstall` once.
