import QtQuick
import Quickshell

// A text label on the bar; left click toggles its dropdown when it has one.
Item {
    id: root

    property alias text: label.text
    property color color: Theme.fg
    property var dropdown: null
    readonly property var window: QsWindow.window
    readonly property bool hovered: area.containsMouse

    signal clicked(var mouse)
    signal scrolled(int delta)

    implicitWidth: label.implicitWidth + Theme.pad * 2
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        color: Theme.hover
        visible: area.containsMouse || (root.dropdown?.visible ?? false)
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: root.color
        textFormat: Text.StyledText
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (root.dropdown && mouse.button === Qt.LeftButton)
                root.dropdown.toggle();
            root.clicked(mouse);
        }
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }
}
