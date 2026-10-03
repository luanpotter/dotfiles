pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // only one dropdown open at a time
    property var openDropdown: null

    // launch through uwsm so apps get their own cgroup scope (see hyprland.lua)
    function run(cmd) {
        Quickshell.execDetached(["uwsm", "app", "--"].concat(cmd));
    }

    function term(cmd) {
        run(["ghostty", "-e"].concat(cmd));
    }

    // a dropdown's "open the full app" button
    function expand(cmd) {
        if (openDropdown)
            openDropdown.visible = false;
        run(cmd);
    }
}
