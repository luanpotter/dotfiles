pragma Singleton

import QtQuick
import Quickshell

// Palette and metrics shared by every widget.
// Square corners and the cyan accent match the Hyprland borders.
Singleton {
    readonly property color bg:      "#e60c0d10"
    readonly property color surface: "#f5111216"
    readonly property color border:  "#1affffff"
    readonly property color hover:   "#0fffffff"

    readonly property color fg:    "#c9ccd3"
    readonly property color muted: "#80858f"
    readonly property color dim:   "#4b4f58"
    readonly property color faint: "#262930"

    readonly property color accent: "#33ccff"
    readonly property color good:   "#00ff99"
    readonly property color warn:   "#ffb454"
    readonly property color bad:    "#ff5c6c"

    readonly property string font: "monospace"
    readonly property int fontSize: 12
    readonly property int barHeight: 28
    readonly property int pad: 10

    // dimmed middle dot for StyledText labels
    readonly property string sep: `<font color="${dim}"> · </font>`

    function tint(text, color) {
        return `<font color="${color}">${text}</font>`;
    }

    // fixed-width rendering of a 0-1 fraction ("0.05", "1.00") so labels
    // never shift; use 4-char words like "mute" alongside it
    function num(f) {
        return Math.max(0, f).toFixed(2);
    }

    // one-char direction marker after a num(): "+" rising, "-" falling,
    // "~" steady; green when the direction is good, red when bad
    function trend(dir, upIsGood) {
        if (dir > 0)
            return tint("+", upIsGood ? good : bad);
        if (dir < 0)
            return tint("-", upIsGood ? bad : good);
        return tint("~", dim);
    }

    // direction of a sampled value, ignoring changes under threshold
    function direction(prev, next, threshold) {
        const d = next - prev;
        return d > threshold ? 1 : d < -threshold ? -1 : 0;
    }
}
