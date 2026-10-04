pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Smart launcher/SUPER+R. Lives in the running shell so no startup cost.
// Default: apps + commands; :emoji, =calc, ?web.
Scope {
    id: root

    property bool open: false
    property var commands: []
    property var emojis: []
    property string calcResult: ""
    property var results: []
    property int selected: 0

    readonly property int maxRows: 10

    function toggle() {
        open = !open;
        if (open) {
            commandsProc.running = true; // refresh in the background
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

    // ---- data sources ----

    // executables on $PATH, minus shell builtins and keywords
    Process {
        id: commandsProc
        running: true
        command: ["bash", "-c", "compgen -c | sort -u | comm -23 - <(compgen -bk | sort -u)"]
        stdout: StdioCollector {
            onStreamFinished: root.commands = text.split("\n").filter(c => c.length > 0)
        }
    }

    // emoji list from Unicode (unicode-emoji) with search keywords from CLDR
    FileView {
        id: emojiTest
        path: "/usr/share/unicode/emoji/emoji-test.txt"
        onLoaded: root.buildEmojis()
    }

    FileView {
        id: emojiAnnotations
        path: "/usr/share/unicode/cldr/common/annotations/en.xml"
        onLoaded: root.buildEmojis()
    }

    // CLDR keys usually omit the U+FE0F variation selector
    function emojiKey(emoji) {
        return emoji.replace(/️/g, "");
    }

    function buildEmojis() {
        if (!emojiTest.loaded || !emojiAnnotations.loaded)
            return;

        // <annotation cp="🔥">af | burn | fire | flame</annotation>; the
        // type="tts" variants (just the name again) don't match this pattern
        // (exec loops: Qt's JS engine has no String.matchAll)
        const keywords = new Map();
        const annotationRe = /<annotation cp="([^"]+)">([^<]*)<\/annotation>/g;
        const annotations = emojiAnnotations.text();
        let m;
        while ((m = annotationRe.exec(annotations)) !== null)
            keywords.set(emojiKey(m[1]), m[2].replace(/&amp;/g, "&"));

        // 1F525 ; fully-qualified # 🔥 E0.6 fire
        const list = [];
        const emojiRe = /; fully-qualified\s+# (\S+) E[\d.]+ (.+)$/gm;
        const test = emojiTest.text();
        while ((m = emojiRe.exec(test)) !== null) {
            const [, emoji, name] = m;
            if (!name.includes("skin tone"))
                list.push({ emoji, name, keywords: keywords.get(emojiKey(emoji)) ?? "" });
        }
        root.emojis = list;
    }

    Process {
        id: calcProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.calcResult = text.trim();
                root.refresh();
            }
        }
    }

    Timer {
        id: calcDebounce
        interval: 60
        onTriggered: {
            calcProc.command = ["qalc", "-t", root.query.slice(1)];
            calcProc.running = true;
        }
    }

    // ---- matching ----

    readonly property string query: input.text

    // lower is better; -1 = no match
    function score(name, q) {
        const n = name.toLowerCase();
        if (n === q)
            return 0;
        if (n.startsWith(q))
            return 1;
        const i = n.indexOf(q);
        if (i > 0 && /[\s\-_.]/.test(n[i - 1]))
            return 2;
        if (i > 0)
            return 3;
        let j = 0;
        for (const c of n)
            if (c === q[j] && ++j === q.length)
                return 4;
        return -1;
    }

    // best of the name score and the keyword score (keywords rank lower)
    function scoreWithKeywords(name, keywords, q) {
        const s = score(name, q);
        const k = keywords ? score(keywords, q) : -1;
        if (k < 0)
            return s;
        return s < 0 ? k + 2 : Math.min(s, k + 2);
    }

    function ranked(items, q, nameOf, keywordsOf) {
        const out = [];
        for (const item of items) {
            const s = scoreWithKeywords(nameOf(item), keywordsOf(item), q);
            if (s >= 0)
                out.push({ item, s });
        }
        out.sort((a, b) => a.s - b.s || nameOf(a.item).length - nameOf(b.item).length);
        return out;
    }

    function webRow(q) {
        return { label: `search "${q}"`, detail: "web", run: () => Global.run(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(q)]) };
    }

    function urlRow(q) {
        if (/\s/.test(q) || !/^(https?:\/\/)?[\w-]+(\.[\w-]+)+(\/\S*)?$/.test(q))
            return null;
        const url = /^https?:\/\//.test(q) ? q : "https://" + q;
        return { label: url, detail: "open", run: () => Global.run(["xdg-open", url]) };
    }

    function refresh() {
        const text = query;
        const rows = [];

        if (text.startsWith(":")) {
            const q = text.slice(1).trim().toLowerCase();
            if (q)
                for (const { item } of ranked(emojis, q, e => e.name, e => e.keywords).slice(0, maxRows))
                    rows.push({ label: item.name, glyph: item.emoji, detail: "emoji", run: () => Quickshell.execDetached(["wl-copy", item.emoji]) });
        } else if (text.startsWith("=")) {
            if (text.length > 1 && calcResult)
                rows.push({ label: calcResult, detail: "copy", run: () => Quickshell.execDetached(["wl-copy", calcResult.replace(/^= /, "")]) });
        } else if (text.startsWith("?")) {
            const q = text.slice(1).trim();
            if (q)
                rows.push(webRow(q));
        } else {
            const q = text.trim().toLowerCase();
            if (q) {
                const url = urlRow(text.trim());
                if (url)
                    rows.push(url);

                // typed a full command line: offer to run it as-is
                if (/\s/.test(text.trim()))
                    rows.push(commandRow(text.trim(), "run"));

                const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
                const appHits = ranked(apps, q, a => a.name, a => [a.genericName].concat(Array.from(a.keywords ?? [])).join(" "));
                const cmdHits = ranked(commands, q, c => c, () => "");

                // merge, apps winning ties against commands
                let a = 0, c = 0;
                while (rows.length < maxRows - 1 && (a < appHits.length || c < cmdHits.length)) {
                    if (c >= cmdHits.length || (a < appHits.length && appHits[a].s <= cmdHits[c].s))
                        rows.push(appRow(appHits[a++].item));
                    else
                        rows.push(commandRow(cmdHits[c++].item, "cmd"));
                }
                rows.push(webRow(text.trim()));
            }
        }

        results = rows;
        selected = 0;
    }

    function appRow(app) {
        return { label: app.name, icon: app.icon, detail: "app", run: () => Global.run([app.id + ".desktop"]) };
    }

    function commandRow(cmd, detail) {
        return {
            label: cmd,
            detail: detail,
            run: () => Global.run(["sh", "-c", cmd]),
            runInTerminal: () => Global.term(["sh", "-c", cmd])
        };
    }

    onQueryChanged: {
        if (query.startsWith("=") && query.length > 1)
            calcDebounce.restart();
        refresh();
    }

    function activate(inTerminal) {
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

                    Repeater {
                        model: root.results

                        Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool current: index === root.selected

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
                                font.family: "Noto Color Emoji" // fonts module, os/arch/core.yaml
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
                                text: row.modelData.label
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
                                text: row.modelData.detail
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
