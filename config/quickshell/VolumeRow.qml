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

    // click or drag anywhere on the row's height to set, scroll to nudge
    Item {
        id: slider

        readonly property real value: Math.min(1, root.audio?.volume ?? 0)

        function setFrom(x) {
            if (root.audio)
                root.audio.volume = Math.max(0, Math.min(1, x / width));
        }

        Layout.preferredWidth: 180
        Layout.preferredHeight: 18

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            color: Theme.faint

            Rectangle {
                width: slider.value * parent.width
                height: parent.height
                color: root.audio?.muted ? Theme.dim : Theme.accent
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: slider.value * (parent.width - width)
            width: 4
            height: 12
            color: drag.pressed || drag.containsMouse ? Theme.fg : Theme.muted
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => slider.setFrom(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    slider.setFrom(mouse.x);
            }
            onWheel: wheel => {
                if (root.audio)
                    root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
            }
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
