import QtQuick
import Quickshell

BarItem {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd") + Theme.sep
        + Qt.formatDateTime(clock.date, "yyyy-MM-dd") + Theme.sep
        + Qt.formatDateTime(clock.date, "HH:mm")

    dropdown: Dropdown {
        owner: root

        ClockPanel {}
    }
}
