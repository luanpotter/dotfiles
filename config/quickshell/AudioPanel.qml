import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var sink
    required property var source

    spacing: 6

    Txt {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        text: root.sink?.description ?? "no output"
        color: Theme.dim
        elide: Text.ElideRight
    }

    VolumeRow {
        node: root.sink
        label: "vol"
    }

    Txt {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.topMargin: 6
        text: root.source?.description ?? "no input"
        color: Theme.dim
        elide: Text.ElideRight
    }

    VolumeRow {
        node: root.source
        label: "mic"
    }

    PanelButton {
        Layout.alignment: Qt.AlignRight
        Layout.topMargin: 6
        text: "mixer"
        onClicked: Global.expand(["pavucontrol"])
    }
}
