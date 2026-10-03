import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// Left click activates, right click opens the app's menu, middle click is
// the secondary action.
Row {
    Repeater {
        model: SystemTray.items

        Item {
            id: cell

            required property var modelData

            implicitWidth: 26
            implicitHeight: Theme.barHeight

            Rectangle {
                anchors.fill: parent
                color: area.containsMouse ? Theme.hover : "transparent"
            }

            IconImage {
                anchors.centerIn: parent
                source: cell.modelData.icon
                implicitSize: 14
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: mouse => {
                    const item = cell.modelData;
                    if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu) {
                            const p = cell.mapToItem(null, 0, cell.height);
                            item.display(cell.QsWindow.window, p.x, p.y);
                        }
                    } else {
                        item.activate();
                    }
                }
                onWheel: wheel => cell.modelData.scroll(wheel.angleDelta.y, false)
            }
        }
    }
}
