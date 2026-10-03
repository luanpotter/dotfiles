import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Screen backlight; scroll to change it, click for a slider.
// Hidden when there is no backlight.
BarItem {
    id: root

    property string device: ""
    property real max: 1
    property real raw: 0
    // same exponent as the hyprland brightness keys, so each 5% step reads as 0.05
    readonly property real level: Math.pow(raw / max, 1 / 4)
    // latest requested level not yet handed to brightnessctl, or -1
    property real pending: -1

    function setLevel(v) {
        v = Math.max(0, Math.min(1, v));
        root.raw = root.max * Math.pow(v, 4); // optimistic, so dragging tracks
        root.pending = v;
        flush();
    }

    // one brightnessctl at a time; a drag only sends its latest position
    function flush() {
        if (setter.running || root.pending < 0)
            return;
        setter.command = ["brightnessctl", "-c", "backlight", "-e4", "-n2", "set", Math.round(root.pending * 100) + "%"];
        root.pending = -1;
        setter.running = true;
    }

    visible: device !== ""
    text: Theme.tint("lcd", Theme.muted) + " " + Theme.num(level)

    onScrolled: delta => setLevel(level + (delta > 0 ? 0.05 : -0.05))

    dropdown: Dropdown {
        owner: root

        Txt {
            text: root.device
            color: Theme.dim
        }

        RowLayout {
            spacing: 10

            Txt {
                Layout.preferredWidth: 28
                text: "lcd"
                color: Theme.muted
            }

            LevelBar {
                value: root.level
                onMoved: value => root.setLevel(value)
                onNudged: dir => root.setLevel(root.level + dir * 0.05)
            }

            Txt {
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignRight
                text: Theme.num(root.level)
            }
        }
    }

    // machine output: "name,class,current,percent,max"
    Process {
        command: ["brightnessctl", "-m", "-c", "backlight"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length < 5)
                    return;
                root.max = Number(f[4]) || 1;
                root.raw = Number(f[2]);
                root.device = f[0];
            }
        }
    }

    Process {
        id: setter
        onExited: root.pending >= 0 ? root.flush() : file.reload()
    }

    FileView {
        id: file
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: root.raw = Number(file.text())
    }

    // sysfs doesn't notify on change, so poll to catch the brightness keys
    Timer {
        interval: 2000
        running: root.device !== ""
        repeat: true
        // skip mid-drag so a stale read doesn't snap the bar back
        onTriggered: {
            if (!setter.running)
                file.reload();
        }
    }
}
