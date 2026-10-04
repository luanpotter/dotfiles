import QtQuick
import Quickshell

BarItem {
    id: root

    text: "sys"
    color: Theme.muted

    dropdown: Dropdown {
        owner: root
        padding: 6

        Repeater {
            model: [
                // keybinds live in hyprland.lua
                { label: "reload", cmd: ["qs", "ipc", "call", "shell", "reload"], shortcut: "super+shift+r" },
                { label: "lock", cmd: ["qs", "ipc", "call", "lock", "lock"], shortcut: "super+shift+l" },
                { label: "suspend", cmd: ["systemctl", "suspend"] },
                { label: "log out", cmd: ["uwsm", "stop"] },
                { label: "reboot", cmd: ["systemctl", "reboot"] },
                { label: "shut down", cmd: ["systemctl", "poweroff"] },
            ]

            MenuRow {
                required property var modelData
                implicitWidth: 180
                text: modelData.label
                detail: modelData.shortcut ?? ""
                onClicked: {
                    Global.openDropdown.visible = false;
                    Quickshell.execDetached(modelData.cmd);
                }
            }
        }
    }
}
