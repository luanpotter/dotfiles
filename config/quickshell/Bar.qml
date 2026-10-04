import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.bg

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: Theme.border
    }

    // left: system status / internals, then tray
    RowLayout {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        spacing: 0

        SysStats {}
        BatteryItem {}
        Tray {}
    }

    Workspaces {
        anchors.centerIn: parent
        monitor: Hyprland.monitorFor(bar.screen)
    }

    // right: keyboard layout, brightness, audio, network, time
    RowLayout {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        spacing: 0

        KeyboardItem {}
        BrightnessItem {}
        AudioItem {}
        NetworkItem {}
        ClockItem {}
        PowerItem {}
    }
}
