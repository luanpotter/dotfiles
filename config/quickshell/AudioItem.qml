import QtQuick
import Quickshell.Services.Pipewire

// Scroll to change volume, middle click to mute.
BarItem {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function level(node, name) {
        if (!node?.audio)
            return Theme.tint(name + " -", Theme.dim);
        if (node.audio.muted)
            return Theme.tint(name + " mute", Theme.dim);
        return Theme.tint(name, Theme.muted) + " " + Theme.num(node.audio.volume);
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    text: level(sink, "vol") + Theme.sep + level(source, "mic")

    onScrolled: delta => {
        const audio = sink?.audio;
        if (audio)
            audio.volume = Math.max(0, Math.min(1, audio.volume + (delta > 0 ? 0.05 : -0.05)));
    }

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    dropdown: Dropdown {
        owner: root

        AudioPanel {
            sink: root.sink
            source: root.source
        }
    }
}
