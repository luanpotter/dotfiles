import QtQuick
import QtQuick.Effects
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

    readonly property int logoSize: Math.round(height * 0.3)

    Image {
        id: logo
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -wallpaper.logoSize * 0.15
        width: wallpaper.logoSize
        height: wallpaper.logoSize
        source: "arch.svg"
        sourceSize: Qt.size(width, height)
        visible: false
    }

    MultiEffect {
        anchors.fill: logo
        source: logo

        colorization: 1.0
        colorizationColor: Theme.faint

        shadowEnabled: true
        shadowColor: Theme.accent
        shadowOpacity: 0.35
        shadowBlur: 1.0
        blurMax: 64
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: logo.bottom
        anchors.topMargin: wallpaper.logoSize * 0.2
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: wallpaper.logoSize * 0.22
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd · yyyy-MM-dd")
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: wallpaper.logoSize * 0.06
        }
    }
}
