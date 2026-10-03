import QtQuick
import QtQuick.Layouts

// Label, flat slider, and a percentage that toggles mute when clicked.
RowLayout {
    id: root

    required property var node
    required property string label
    readonly property var audio: node?.audio ?? null

    spacing: 10

    Txt {
        Layout.preferredWidth: 28
        text: root.label
        color: Theme.muted
    }

    LevelBar {
        value: root.audio?.volume ?? 0
        active: !(root.audio?.muted ?? false)
        onMoved: value => {
            if (root.audio)
                root.audio.volume = value;
        }
        onNudged: dir => {
            if (root.audio)
                root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + dir * 0.05));
        }
    }

    Txt {
        Layout.preferredWidth: 32
        horizontalAlignment: Text.AlignRight
        text: root.audio?.muted ? "mute" : Theme.num(root.audio?.volume ?? 0)
        color: root.audio?.muted ? Theme.dim : Theme.fg

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.audio)
                    root.audio.muted = !root.audio.muted;
            }
        }
    }
}
