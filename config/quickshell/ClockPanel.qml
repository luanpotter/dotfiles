pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// Seconds clock over a month calendar. Scroll or ‹ › to change month,
// click the month name to jump back to today.
ColumnLayout {
    id: root

    property int month: clock.date.getMonth()
    property int year: clock.date.getFullYear()

    function shift(n) {
        const m = month + n;
        year += Math.floor(m / 12);
        month = ((m % 12) + 12) % 12;
    }

    function goToday() {
        month = clock.date.getMonth();
        year = clock.date.getFullYear();
    }

    spacing: 8

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Connections {
        target: root.QsWindow.window
        function onVisibleChanged() {
            if (root.QsWindow.window.visible)
                root.goToday();
        }
    }

    WheelHandler {
        onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
    }

    Txt {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "HH:mm:ss")
        font.pixelSize: 30
        font.letterSpacing: 1
    }

    Txt {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy").toLowerCase()
        color: Theme.muted
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: Theme.border
    }

    RowLayout {
        Layout.fillWidth: true

        PanelButton {
            text: "‹"
            onClicked: root.shift(-1)
        }

        Txt {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.locale().standaloneMonthName(root.month).toLowerCase() + " " + root.year

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.goToday()
            }
        }

        PanelButton {
            text: "›"
            onClicked: root.shift(1)
        }
    }

    DayOfWeekRow {
        Layout.fillWidth: true

        delegate: Txt {
            required property var model
            text: model.shortName.slice(0, 2).toLowerCase()
            color: Theme.dim
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MonthGrid {
        id: grid
        Layout.fillWidth: true
        month: root.month
        year: root.year
        spacing: 2

        delegate: Item {
            id: cell
            required property var model
            implicitWidth: 28
            implicitHeight: 22

            Rectangle {
                anchors.fill: parent
                color: cell.model.today ? Theme.accent : "transparent"
            }

            Txt {
                anchors.centerIn: parent
                text: cell.model.day
                color: cell.model.today ? "#0c0d10" : cell.model.month === grid.month ? Theme.fg : Theme.dim
            }
        }
    }
}
