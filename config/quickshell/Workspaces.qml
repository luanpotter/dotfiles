pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

// One square per workspace: accent = focused, light = visible on an
// unfocused monitor, grey = has windows, faint = empty.
Row {
    id: root

    required property var monitor

    // smw.lua names workspaces m<monitor>:<n>; collect this monitor's 1..9
    readonly property var slots: {
        const out = [];
        for (const ws of Hyprland.workspaces.values) {
            const m = ws.name.match(/^m\d+:(\d+)$/);
            if (m && ws.monitor === root.monitor)
                out[parseInt(m[1]) - 1] = ws;
        }
        return out;
    }

    Repeater {
        model: 9

        Item {
            id: cell

            required property int index
            readonly property var ws: root.slots[index] ?? null
            readonly property bool occupied: ws !== null && ws.toplevels.values.length > 0

            implicitWidth: mark.width + 8
            implicitHeight: Theme.barHeight

            Rectangle {
                id: mark
                anchors.centerIn: parent
                width: cell.ws?.active ? 16 : 6
                height: 6
                color: {
                    if (cell.ws?.focused) return Theme.accent;
                    if (cell.ws?.active) return Theme.fg;
                    if (cell.ws?.urgent) return Theme.bad;
                    return cell.occupied ? Theme.muted : Theme.faint;
                }

                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: cell.ws?.activate()
            }
        }
    }
}
