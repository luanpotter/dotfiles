import QtQuick
import Quickshell
import Quickshell.Io
import "LauncherMatch.js" as Match

// "#notes" mode (SUPER+N): text files in ~/notes (created by the shell
// module, not synced); Enter copies the file's contents.
Scope {
    id: root

    required property int limit

    signal finished

    readonly property string dir: Quickshell.env("HOME") + "/notes"

    property var files: []

    // re-list the folder in the background (called when the launcher opens)
    function refresh() {
        listProc.running = true;
    }

    Process {
        id: listProc
        running: true
        command: ["find", root.dir, "-maxdepth", "1", "-type", "f", "-printf", "%f\\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(f => f.length > 0).sort();
                root.finished();
            }
        }
    }

    // searchable items, built once (not per keystroke)
    readonly property var items: files.map(f => ({ name: f, nameLc: f.toLowerCase(), kwLc: "" }))

    readonly property var cache: ({})

    function rows(text) {
        const q = text.trim().toLowerCase();
        // no query: the whole list, alphabetically
        const hits = q ? Match.ranked(cache, items, q).map(h => h.item) : items;
        return hits.slice(0, limit).map(item => ({
            label: item.name,
            detail: "note",
            // through stdin, so the contents arrive byte for byte
            run: () => Quickshell.execDetached(["sh", "-c", "wl-copy < \"$1\"", "sh", root.dir + "/" + item.name])
        }));
    }
}
