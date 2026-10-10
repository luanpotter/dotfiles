pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Floating card with a word's dictionary entry (scripts/dict-def), opened by
// #def. The text is selectable; Esc, q or a click outside closes it, j/k and
// the arrows scroll.
Scope {
    id: root

    property bool open: false
    property string entry: ""

    function show(word) {
        entry = "";
        proc.command = ["dict-def", word];
        proc.running = true;
        open = true;
    }

    function close() {
        open = false;
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: root.entry = text.trim()
        }
    }

    PanelWindow {
        visible: root.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-definition"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"

        onVisibleChanged: if (visible)
            body.forceActiveFocus()

        // click outside the box closes
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.2
            width: 680
            height: Math.min(body.implicitHeight + 2, parent.height * 0.6)
            color: Theme.bg
            border.width: 1
            border.color: Theme.border

            // swallow clicks inside the box
            MouseArea {
                anchors.fill: parent
            }

            ScrollView {
                id: scroll
                anchors.fill: parent
                anchors.margins: 1

                TextArea {
                    id: body
                    text: root.entry
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    padding: 12
                    background: null
                    color: Theme.fg
                    selectionColor: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize

                    Keys.onPressed: event => {
                        const bar = scroll.ScrollBar.vertical;
                        const step = 40 / Math.max(body.height, 1);
                        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                            root.close();
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                            bar.position = Math.min(bar.position + step, 1 - bar.size);
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                            bar.position = Math.max(bar.position - step, 0);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
