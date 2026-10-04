import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: wallpaper

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Theme.bg

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Backdrop {
        anchors.fill: parent
        colors: Theme.colors
        now: clock.date
        font: Theme.font
    }
}
