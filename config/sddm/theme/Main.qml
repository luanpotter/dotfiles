import QtQuick

// Palette mirrored from config/quickshell/Theme.qml
Rectangle {
    id: root

    readonly property color surface: "#111216"
    readonly property color border:  "#1affffff"
    readonly property color fg:      "#c9ccd3"
    readonly property color muted:   "#80858f"
    readonly property color dim:     "#4b4f58"
    readonly property color accent:  "#33ccff"
    readonly property color warn:    "#ffb454"
    readonly property color bad:     "#ff5c6c"
    readonly property string font:   "monospace"
    readonly property string sep:    `<font color="${dim}"> · </font>`

    property string firstUser: ""
    readonly property string user: userModel.lastUser || firstUser
    property bool failed: false
    property bool busy: false
    property date now: new Date()

    color: "#0c0d10"

    Repeater {
        model: userModel
        Item {
            required property int index
            required property string name
            Component.onCompleted: if (index === 0)
                root.firstUser = name
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.failed = true;
            password.text = "";
            shake.restart();
        }
    }

    function login() {
        if (busy || !user)
            return;
        busy = true;
        failed = false;
        sddm.login(user, password.text, sessionModel.lastIndex);
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            color: root.fg
            font.family: root.font
            font.pixelSize: 96
            font.weight: Font.Light
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "ddd").toLowerCase() + root.sep
                + Qt.formatDateTime(root.now, "yyyy-MM-dd")
            textFormat: Text.StyledText
            color: root.muted
            font.family: root.font
            font.pixelSize: 14
        }

        Item { width: 1; height: 48 }

        Rectangle {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 36
            color: root.surface
            border.width: 1
            border.color: root.failed ? root.bad
                : password.activeFocus ? root.accent : root.border

            transform: Translate { id: nudge }

            SequentialAnimation {
                id: shake
                loops: 2
                NumberAnimation { target: nudge; property: "x"; to: 6;  duration: 40 }
                NumberAnimation { target: nudge; property: "x"; to: -6; duration: 80 }
                NumberAnimation { target: nudge; property: "x"; to: 0;  duration: 40 }
            }

            TextInput {
                id: password
                anchors {
                    left: parent.left
                    leftMargin: 10
                    right: caps.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                focus: true
                clip: true
                enabled: !root.busy
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: root.fg
                selectionColor: root.accent
                font.family: root.font
                font.pixelSize: 12
                onTextEdited: root.failed = false
                onAccepted: root.login()
                Keys.onEscapePressed: text = ""
                Component.onCompleted: forceActiveFocus()
            }

            Text {
                id: caps
                anchors {
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                text: keyboard.capsLock ? "caps" : ""
                color: root.warn
                font.family: root.font
                font.pixelSize: 12
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 10
            text: "denied"
            color: root.bad
            opacity: root.failed ? 1 : 0
            font.family: root.font
            font.pixelSize: 12
        }
    }

    // clicking anywhere returns focus to the field
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: password.forceActiveFocus()
    }
}
