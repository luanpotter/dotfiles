pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

// Nearby wifi networks; clicking a saved one connects, anything else
// (new networks, VPNs, wired setup) goes to nmtui.
ColumnLayout {
    id: root

    required property var wifi
    required property var wired

    // fixed so the panel doesn't resize as networks are discovered;
    // long names are elided by MenuRow
    readonly property int rowWidth: 240

    readonly property var networks: {
        if (!wifi)
            return [];
        return Array.from(wifi.networks.values)
            .filter(n => n.name)
            .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
            .slice(0, 8);
    }

    spacing: 2

    // only scan while the panel is open
    Binding {
        when: root.wifi !== null
        target: root.wifi
        property: "scannerEnabled"
        value: (root.QsWindow.window as QsWindow)?.visible ?? false
    }

    MenuRow {
        visible: root.wired !== null
        implicitWidth: root.rowWidth
        text: "ethernet"
        detail: root.wired?.name ?? ""
        color: Theme.accent
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        visible: root.wifi !== null

        Txt {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            text: "wifi"
            color: Theme.muted
        }

        PanelButton {
            text: Networking.wifiEnabled ? "on" : "off"
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Repeater {
        model: root.networks

        MenuRow {
            required property var modelData
            implicitWidth: root.rowWidth
            text: modelData.name
            detail: modelData.stateChanging ? "…" : Theme.num(modelData.signalStrength)
            color: modelData.connected ? Theme.accent : modelData.known ? Theme.fg : Theme.muted
            onClicked: {
                if (modelData.connected)
                    return;
                if (modelData.known)
                    modelData.connect();
                else
                    Global.expand(["ghostty", "-e", "nmtui"]);
            }
        }
    }

    PanelButton {
        Layout.alignment: Qt.AlignRight
        Layout.topMargin: 8
        text: "nmtui"
        onClicked: Global.expand(["ghostty", "-e", "nmtui"])
    }
}
