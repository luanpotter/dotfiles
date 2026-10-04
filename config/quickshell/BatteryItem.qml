import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

BarItem {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property real charge: dev.percentage
    readonly property int dir: dev.state === UPowerDeviceState.Charging ? 1
        : dev.state === UPowerDeviceState.Discharging ? -1 : 0

    function duration(secs) {
        const h = Math.floor(secs / 3600);
        const m = Math.round((secs % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    visible: dev.isLaptopBattery
    color: dir > 0 ? Theme.fg : charge <= 0.15 ? Theme.bad : charge <= 0.3 ? Theme.warn : Theme.fg
    text: Theme.tint("pwr", Theme.muted) + " " + Theme.num(charge) + Theme.trend(dir, true)

    dropdown: Dropdown {
        owner: root

        Repeater {
            model: [
                ["state", UPowerDeviceState.toString(root.dev.state).toLowerCase()],
                ["charge", Theme.num(root.charge)],
                root.dev.timeToEmpty > 0 ? ["empty in", root.duration(root.dev.timeToEmpty)]
                    : root.dev.timeToFull > 0 ? ["full in", root.duration(root.dev.timeToFull)]
                    : null,
                ["rate", Math.abs(root.dev.changeRate).toFixed(1) + " W"],
            ].filter(row => row)

            RowLayout {
                id: row
                required property var modelData
                spacing: 16

                Txt {
                    Layout.preferredWidth: 64
                    text: row.modelData[0]
                    color: Theme.muted
                }

                Txt {
                    text: row.modelData[1]
                }
            }
        }
    }
}
