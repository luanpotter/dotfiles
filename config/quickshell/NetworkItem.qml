import QtQuick
import Quickshell.Networking

BarItem {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null

    text: {
        if (wired)
            return Theme.tint("eth", Theme.muted) + " " + wired.name;
        if (network)
            return Theme.tint("wlan", Theme.muted) + " " + network.name;
        return Theme.tint("offline", Theme.dim);
    }

    dropdown: Dropdown {
        owner: root

        NetworkPanel {
            wifi: root.wifi
            wired: root.wired
        }
    }
}
