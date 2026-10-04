pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

// Smart launcher/SUPER+R. Lives in the running shell so no startup cost.
// Default: apps + commands; :emoji, =calc, ?web; modules in each Launcher* file.
Scope {
    id: root

    property bool open: false
    property var results: []
    property int selected: 0

    readonly property int maxRows: 10

    function toggle() {
        open = !open;
        if (open) {
            apps.refreshCommands(); // refresh in the background
        } else {
            input.text = "";
        }
    }

    function close() {
        open = false;
        input.text = "";
    }

    GlobalShortcut {
        name: "launcher"
        description: "Open the launcher"
        onPressed: root.toggle()
    }

    // ---- modes ----

    LauncherApps {
        id: apps
    }

    LauncherSymbols {
        id: symbols
        limit: root.maxRows
    }

    LauncherCalc {
        id: calc
        onFinished: root.refresh()
    }

    LauncherWeb {
        id: web
    }

    readonly property string query: input.text

    function refresh() {
        const text = query;
        let rows = [];

        if (text.startsWith(":")) {
            rows = symbols.rows(text.slice(1));
        } else if (text.startsWith("=")) {
            rows = calc.rows(text.slice(1));
        } else if (text.startsWith("?")) {
            rows = web.rows(text.slice(1));
        } else {
            const q = text.trim();
            if (q) {
                const url = web.urlRow(q);
                if (url)
                    rows.push(url);
                rows = rows.concat(apps.rows(q, maxRows - 1 - rows.length));
                rows.push(web.searchRow(q));
            }
        }

        results = rows;
        selected = 0;
    }

    // search after the typed character is drawn; fast typing collapses into
    // one search (Qt.callLater dedupes)
    property bool searchPending: false

    onQueryChanged: {
        if (query.startsWith("=") && query.length > 1)
            calc.update(query.slice(1));
        searchPending = true;
        Qt.callLater(runSearch);
    }

    function runSearch() {
        if (!searchPending)
            return;
        searchPending = false;
        refresh();
    }

    function activate(inTerminal) {
        runSearch(); // Enter right after typing: don't act on stale results
        const row = results[selected];
        if (!row)
            return;
        if (inTerminal && row.runInTerminal)
            row.runInTerminal();
        else
            row.run();
        close();
    }

    // ---- window ----

    PanelWindow {
        visible: root.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-launcher"
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
            input.forceActiveFocus()

        // click outside the box closes
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: box
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.25
            width: 560
            height: column.implicitHeight + 2
            color: Theme.bg
            border.width: 1
            border.color: Theme.border

            // swallow clicks inside the box
            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: column
                x: 1
                y: 1
                width: parent.width - 2

                Rectangle {
                    width: parent.width
                    height: 36
                    color: Theme.surface

                    Text {
                        id: prompt
                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        text: root.query.startsWith(":") ? "emoji"
                            : root.query.startsWith("=") ? "calc"
                            : root.query.startsWith("?") ? "web" : "run"
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }

                    TextInput {
                        id: input
                        anchors {
                            left: prompt.right
                            leftMargin: 10
                            right: parent.right
                            rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        focus: true
                        clip: true
                        color: Theme.fg
                        selectionColor: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize

                        Text {
                            visible: !input.text
                            text: ":emoji  =calc  ?web"
                            color: Theme.dim
                            font: input.font
                        }

                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier;
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && event.key === Qt.Key_J)) {
                                root.selected = Math.min(root.selected + 1, root.results.length - 1);
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K)) {
                                root.selected = Math.max(root.selected - 1, 0);
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.activate(event.modifiers & Qt.ShiftModifier);
                            } else {
                                return;
                            }
                            event.accepted = true;
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                    visible: root.results.length > 0
                }

                Column {
                    width: parent.width
                    topPadding: root.results.length ? 4 : 0
                    bottomPadding: root.results.length ? 4 : 0

                    // fixed rows that update in place, rather than rebuilding
                    // (and re-rendering emoji) on every keystroke
                    Repeater {
                        model: root.maxRows

                        Rectangle {
                            id: row
                            required property int index
                            readonly property var modelData: root.results[index] ?? {}
                            readonly property bool current: index === root.selected

                            visible: index < root.results.length
                            width: parent.width
                            height: 24
                            color: current ? Theme.hover : "transparent"

                            IconImage {
                                id: icon
                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                implicitSize: 16
                                visible: !!row.modelData.icon
                                source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                            }

                            Text {
                                id: glyph
                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                visible: !!row.modelData.glyph
                                text: row.modelData.glyph ?? ""
                                color: row.current ? Theme.accent : Theme.fg
                                // emoji font from the fonts module (os/arch/core.yaml)
                                font.family: row.modelData.emoji ? "Noto Color Emoji" : Theme.font
                                font.pixelSize: 14
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: (row.modelData.icon || row.modelData.glyph) ? 36 : 10
                                    right: detail.left
                                    rightMargin: 12
                                    verticalCenter: parent.verticalCenter
                                }
                                text: row.modelData.label ?? ""
                                elide: Text.ElideRight
                                color: row.current ? Theme.accent : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                id: detail
                                anchors {
                                    right: parent.right
                                    rightMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                text: row.modelData.detail ?? ""
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.selected = row.index
                                onClicked: root.activate(false)
                            }
                        }
                    }
                }
            }
        }
    }
}
