pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Active keyboard layout; the dropdown switches to a specific one. Layouts
// come from Hyprland (kb_layout/kb_variant in hyprland.lua), so nothing is
// hardcoded here. Also cycled by scripts/toggle_keyboard_layout.
BarItem {
    id: root

    property var layouts: []
    property int active: 0

    text: Theme.tint("kbd", Theme.muted) + " " + (layouts[active]?.code ?? "")

    // main keyboard's layouts and active index
    Process {
        id: query
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const kb = JSON.parse(text).keyboards.find(k => k.main);
                if (!kb)
                    return;
                const variants = kb.variant.split(",");
                root.layouts = kb.layout.split(",").map((code, i) => ({ code, variant: variants[i] ?? "" }));
                root.active = kb.active_layout_index;
            }
        }
    }

    // re-query on layout switches (from anywhere) and config reloads
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout" || event.name === "configreloaded")
                query.running = true;
        }
    }

    dropdown: Dropdown {
        owner: root
        padding: 6

        Repeater {
            model: root.layouts

            MenuRow {
                required property var modelData
                required property int index
                implicitWidth: 140
                text: modelData.code
                detail: modelData.variant
                color: index === root.active ? Theme.accent : Theme.fg
                onClicked: {
                    Global.openDropdown.visible = false;
                    Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", String(index)]);
                }
            }
        }
    }
}
