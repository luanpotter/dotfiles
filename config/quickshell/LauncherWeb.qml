import QtQuick
import Quickshell

// "?" mode, plus the URL and web search rows of the default mode. Opens in
// the default browser.
Scope {
    function searchRow(q) {
        return { label: `search "${q}"`, detail: "web", run: () => Global.run(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(q)]) };
    }

    // anything URL-like (no spaces, has a dot) gets an "open" row
    function urlRow(q) {
        if (/\s/.test(q) || !/^(https?:\/\/)?[\w-]+(\.[\w-]+)+(\/\S*)?$/.test(q))
            return null;
        const url = /^https?:\/\//.test(q) ? q : "https://" + q;
        return { label: url, detail: "open", run: () => Global.run(["xdg-open", url]) };
    }

    function rows(text) {
        const q = text.trim();
        return q ? [searchRow(q)] : [];
    }
}
