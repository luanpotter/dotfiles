//@ pragma UseQApplication
// UseQApplication is needed for system tray menus.

import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }
}
