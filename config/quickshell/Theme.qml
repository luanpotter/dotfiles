pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Palette and metrics shared by every widget.
// Colors live in colors.json so hyprland.lua can read them too.
Singleton {
    property FileView colorsFile: FileView {
        path: Quickshell.shellDir + "/colors.json"
        blockLoading: true
    }
    readonly property var colors: JSON.parse(colorsFile.text())

    readonly property color bg:      colors.bg
    readonly property color surface: colors.surface
    readonly property color border:  colors.border
    readonly property color hover:   colors.hover

    readonly property color fg:    colors.fg
    readonly property color muted: colors.muted
    readonly property color dim:   colors.dim
    readonly property color faint: colors.faint

    readonly property color accent: colors.accent
    readonly property color good:   colors.good
    readonly property color warn:   colors.warn
    readonly property color bad:    colors.bad

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
