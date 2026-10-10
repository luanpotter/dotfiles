import QtQuick
import Quickshell
import Quickshell.Io

// #def mode: GCIDE (Webster's 1913) headwords, fuzzy matched by
// scripts/dict-def (fzf over its index, so the 130k words never reach JS),
// each row showing how the definition starts. Enter copies the word and
// opens the full entry in a floating card (LauncherDefinition).
Scope {
    id: root

    required property int limit

    property string word: ""
    // matches belong to `answered`, which lags `word` until dict-def replies
    property string asked: ""
    property string answered: ""
    property var matches: []

    // emitted when dict-def answers, so the launcher can redraw its rows
    signal finished

    // debounced: dict-def runs once typing pauses
    function update(text) {
        word = text.trim();
        debounce.restart();
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                root.answered = root.asked;
                root.matches = text.split("\n").filter(l => l).map(l => {
                    const [name, pos, def] = l.split("\t");
                    return { name, pos, def };
                });
                root.finished();
                // typed on while this ran: search again for the latest
                if (root.word !== root.asked)
                    debounce.restart();
            }
        }
    }

    Timer {
        id: debounce
        interval: 60
        onTriggered: {
            if (!root.word || proc.running)
                return;
            root.asked = root.word;
            proc.command = ["dict-def", "--search", root.word, String(root.limit)];
            proc.running = true;
        }
    }

    LauncherDefinition {
        id: definition
    }

    function open(word) {
        Quickshell.execDetached(["wl-copy", word]);
        definition.show(word);
    }

    function rows(text) {
        const w = text.trim();
        if (!w || w !== answered)
            return [];
        return matches.map(m => ({
            label: m.def ? m.name + " — " + m.def : m.name,
            detail: m.pos,
            run: () => open(m.name)
        }));
    }
}
