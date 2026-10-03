import QtQuick

// Flat 0-1 slider: click or drag anywhere on its height to set, scroll to nudge.
Item {
    id: root

    property real value: 0
    // dimmed fill, e.g. when muted
    property bool active: true

    signal moved(real value)
    signal nudged(int dir)

    implicitWidth: 180
    implicitHeight: 18

    function setFrom(x) {
        root.moved(Math.max(0, Math.min(1, x / width)));
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        color: Theme.faint

        Rectangle {
            width: Math.min(1, root.value) * parent.width
            height: parent.height
            color: root.active ? Theme.accent : Theme.dim
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: Math.min(1, root.value) * (parent.width - width)
        width: 4
        height: 12
        color: drag.pressed || drag.containsMouse ? Theme.fg : Theme.muted
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFrom(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.setFrom(mouse.x);
        }
        onWheel: wheel => root.nudged(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
