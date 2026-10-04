import QtQuick
import Quickshell
import Quickshell.Io

// "=" mode: evaluates with qalc (libqalculate); Enter copies the result.
Scope {
    id: root

    property string result: ""
    property string expr: ""

    // emitted when qalc answers, so the launcher can redraw its rows
    signal finished

    // debounced: qalc runs once typing pauses
    function update(expr) {
        root.expr = expr;
        debounce.restart();
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                root.result = text.trim();
                root.finished();
            }
        }
    }

    Timer {
        id: debounce
        interval: 60
        onTriggered: {
            proc.command = ["qalc", "-t", root.expr];
            proc.running = true;
        }
    }

    function rows(text) {
        if (!text || !result)
            return [];
        return [{ label: result, detail: "copy", run: () => Quickshell.execDetached(["wl-copy", result.replace(/^= /, "")]) }];
    }
}
