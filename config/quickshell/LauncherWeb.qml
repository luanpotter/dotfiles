import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// "?" mode, plus the URL and web search rows of the default mode. Opens in
// the default browser and focuses it.
Scope {
    id: root

    // app id of the default browser (os/commons/browser.yaml sets it)
    property string browserClass: ""

    Process {
        running: true
        command: ["xdg-settings", "get", "default-web-browser"]
        stdout: StdioCollector {
            onStreamFinished: {
                const id = text.trim().replace(/\.desktop$/, "");
                root.browserClass = DesktopEntries.byId(id)?.startupClass || id;
            }
        }
    }

    function open(url) {
        Global.run(["xdg-open", url]);
        focusBrowser.restart();
    }

    // wait for the launcher to release the keyboard first; a cold-started
    // browser has no window yet and gets focus on its own
    Timer {
        id: focusBrowser
        interval: 300
        onTriggered: ToplevelManager.toplevels.values.find(t => t.appId === root.browserClass)?.activate()
    }

    function searchRow(q) {
        return { label: `search "${q}"`, detail: "web", run: () => open("https://duckduckgo.com/?q=" + encodeURIComponent(q)) };
    }

    // anything URL-like (no spaces, has a dot) gets an "open" row
    function urlRow(q) {
        if (/\s/.test(q) || !/^(https?:\/\/)?[\w-]+(\.[\w-]+)+(\/\S*)?$/.test(q))
            return null;
        const url = /^https?:\/\//.test(q) ? q : "https://" + q;
        return { label: url, detail: "open", run: () => open(url) };
    }

    function rows(text) {
        const q = text.trim();
        return q ? [searchRow(q)] : [];
    }
}
