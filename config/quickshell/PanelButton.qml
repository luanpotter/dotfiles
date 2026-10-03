import QtQuick

// Small outlined text button used inside dropdowns.
Item {
    id: root

    property string text

    signal clicked

    implicitWidth: label.implicitWidth + 14
    implicitHeight: label.implicitHeight + 8

    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Theme.hover : "transparent"
        border.color: Theme.border
        border.width: 1
    }

    Txt {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: area.containsMouse ? Theme.accent : Theme.muted
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
