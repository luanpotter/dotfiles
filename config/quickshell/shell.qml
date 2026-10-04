//@ pragma UseQApplication
// UseQApplication is needed for system tray menus.

import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    // `qs ipc call shell reload`: Hyprland config and this shell together,
    // so colors.json changes reach both
    IpcHandler {
        target: "shell"

        function reload(): void {
            Quickshell.execDetached(["hyprctl", "reload"]);
            Quickshell.reload(false);
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }

    Lock {}
}
