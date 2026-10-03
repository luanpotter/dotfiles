import QtQuick
import QtQuick.Layouts

// Full-width clickable row with an optional dim detail on the right.
Item {
    id: root

    property string text
    property string detail
    property color color: Theme.fg

    signal clicked

    Layout.fillWidth: true
    implicitWidth: Math.max(160, label.implicitWidth + detailLabel.implicitWidth + 32)
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Theme.hover : "transparent"
    }

    Txt {
        id: label
        anchors {
            left: parent.left
            leftMargin: 6
            right: detailLabel.left
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: root.text
        color: area.containsMouse ? Theme.accent : root.color
        elide: Text.ElideRight
    }

    Txt {
        id: detailLabel
        anchors {
            right: parent.right
            rightMargin: 6
            verticalCenter: parent.verticalCenter
        }
        text: root.detail
        color: Theme.dim
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
