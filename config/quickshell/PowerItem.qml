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
                // also reloads this shell, so colors.json changes reach both
                { label: "reload", cmd: ["hyprctl", "reload"], reloadShell: true },
                { label: "suspend", cmd: ["systemctl", "suspend"] },
                { label: "log out", cmd: ["uwsm", "stop"] },
                { label: "reboot", cmd: ["systemctl", "reboot"] },
                { label: "shut down", cmd: ["systemctl", "poweroff"] },
            ]

            MenuRow {
                required property var modelData
                implicitWidth: 140
                text: modelData.label
                onClicked: {
                    Global.openDropdown.visible = false;
                    Quickshell.execDetached(modelData.cmd);
                    if (modelData.reloadShell)
                        Quickshell.reload(false);
                }
            }
        }
    }
}
