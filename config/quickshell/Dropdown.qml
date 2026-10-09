import QtQuick
import QtQuick.Layouts
import Quickshell

// Panel hanging flush under its bar item. Closes once the pointer has left
// both the panel and its bar item.
PopupWindow {
    id: root

    required property var owner
    default property alias content: body.data
    property int padding: 14

    function toggle() {
        if (visible) {
            visible = false;
            return;
        }
        if (Global.openDropdown && Global.openDropdown !== root)
            Global.openDropdown.visible = false;
        Global.openDropdown = root;
        visible = true;
    }

    anchor.item: owner
    anchor.rect.width: owner.width
    anchor.rect.height: owner.height
    // valid, but the Qt 6.12 linter rejects it: quickshell's type info lacks
    // Edges::Flags; see https://github.com/quickshell-mirror/quickshell/pull/1220
    anchor.edges: Edges.Bottom // qmllint disable incompatible-type
    anchor.gravity: Edges.Bottom // qmllint disable incompatible-type

    implicitWidth: body.implicitWidth + padding * 2
    implicitHeight: body.implicitHeight + padding * 2
    color: "transparent"

    // Bar and panel are separate surfaces, so moving between them briefly
    // hovers neither; deferring to the next event loop tick bridges that.
    Timer {
        interval: 0
        running: root.visible && !hover.hovered && !root.owner.hovered
        onTriggered: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        border.color: Theme.border
        border.width: 1

        // on the ancestor of all content so hovering children still counts
        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (!hovered && !root.owner.hovered)
                    root.visible = false;
            }
        }

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 10
        }
    }
}
