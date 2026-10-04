import QtQuick
import QtQuick.Effects

// Arch logo wallapper with clock
Rectangle {
    id: root

    required property var colors // colors.json contents
    required property date now
    property string font: "monospace"

    readonly property int logoSize: Math.round(height * 0.3)

    color: colors.bg

    Image {
        id: logo
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.logoSize * 0.15
        width: root.logoSize
        height: root.logoSize
        source: "arch.svg"
        sourceSize: Qt.size(width, height)
        visible: false
    }

    MultiEffect {
        anchors.fill: logo
        source: logo

        colorization: 1.0
        colorizationColor: root.colors.faint

        shadowEnabled: true
        shadowColor: root.colors.accent
        shadowOpacity: 0.35
        shadowBlur: 1.0
        blurMax: 64
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: logo.bottom
        anchors.topMargin: root.logoSize * 0.2
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            color: root.colors.dim
            font.family: root.font
            font.pixelSize: root.logoSize * 0.22
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "dddd · yyyy-MM-dd")
            color: root.colors.faint
            font.family: root.font
            font.pixelSize: root.logoSize * 0.06
        }
    }
}
