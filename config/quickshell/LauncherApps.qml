import QtQuick
import Quickshell
import Quickshell.Io
import "LauncherMatch.js" as Match

// Default mode: desktop apps and commands on $PATH, plus running a typed
// command line as-is. Apps launch through uwsm (Global.run); commands can
// also run in a terminal (shift+enter).
Scope {
    id: root

    property var commands: []

    // re-read $PATH in the background (called when the launcher opens)
    function refreshCommands() {
        commandsProc.running = true;
    }

    // executables on $PATH, minus shell builtins and keywords
    Process {
        id: commandsProc
        running: true
        command: ["bash", "-c", "compgen -c | sort -u | comm -23 - <(compgen -bk | sort -u)"]
        stdout: StdioCollector {
            onStreamFinished: root.commands = text.split("\n").filter(c => c.length > 0)
        }
    }

    // searchable items, built once (not per keystroke)
    readonly property var appItems: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .map(a => ({
            name: a.name,
            nameLc: a.name.toLowerCase(),
            kwLc: [a.genericName].concat(Array.from(a.keywords ?? [])).join(" ").toLowerCase(),
            app: a
        }))

    readonly property var commandItems: commands.map(c => ({ name: c, nameLc: c.toLowerCase(), kwLc: "" }))

    readonly property var appCache: ({})
    readonly property var commandCache: ({})

    // up to max rows for the (trimmed, non-empty) query
    function rows(text, max) {
        const out = [];

        // typed a full command line: offer to run it as-is
        if (/\s/.test(text))
            out.push(commandRow(text, "run"));

        const q = text.toLowerCase();
        const appHits = Match.ranked(appCache, appItems, q);
        const cmdHits = Match.ranked(commandCache, commandItems, q);

        // merge, apps winning ties against commands
        let a = 0, c = 0;
        while (out.length < max && (a < appHits.length || c < cmdHits.length)) {
            if (c >= cmdHits.length || (a < appHits.length && appHits[a].s <= cmdHits[c].s))
                out.push(appRow(appHits[a++].item.app));
            else
                out.push(commandRow(cmdHits[c++].item.name, "cmd"));
        }
        return out;
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
}
