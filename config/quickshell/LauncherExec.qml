import QtQuick
import Quickshell

// #exec mode: runs a command in a new ghostty window with interactive bash.
Scope {
    id: root

    function exec(cmd) {
        Global.run(["ghostty", "-e", "bash", "-ic", 'eval "$1"; exec bash', "bash", cmd]);
    }

    function rows(text) {
        const cmd = text.trim();
        return cmd ? [{ label: cmd, detail: "exec", run: () => exec(cmd) }] : [];
    }
}
