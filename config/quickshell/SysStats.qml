import QtQuick
import Quickshell.Io

// cpu/mem from /proc every 2s; click opens btop.
BarItem {
    id: root

    property real cpu: 0
    property real mem: 0
    property int cpuDir: 0
    property int memDir: 0
    property var lastCpu: null

    color: Theme.muted
    text: Theme.tint("cpu", Theme.dim) + " " + Theme.num(cpu) + Theme.trend(cpuDir, false)
        + Theme.sep + Theme.tint("mem", Theme.dim) + " " + Theme.num(mem) + Theme.trend(memDir, false)

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton)
            Global.term(["btop"]);
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                const cpu = dt > 0 ? 1 - (idle - root.lastCpu.idle) / dt : 0;
                if (root.cpu > 0)
                    root.cpuDir = Theme.direction(root.cpu, cpu, 0.02);
                root.cpu = cpu;
            }
            root.lastCpu = { total, idle };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = meminfo.text();
            const get = key => Number(t.match(new RegExp(`^${key}:\\s+(\\d+)`, "m"))[1]);
            const mem = 1 - get("MemAvailable") / get("MemTotal");
            // skip the first sample so startup doesn't flash "+"
            if (root.mem > 0)
                root.memDir = Theme.direction(root.mem, mem, 0.005);
            root.mem = mem;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }
}
