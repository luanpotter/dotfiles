import QtQuick

// Same screen as the quickshell wallpaper: Backdrop.qml and arch.svg are
// copied in at install, and theme.conf (read via `config`) is generated
// from colors.json. See os/arch/core.yaml.
Item {
    id: root

    readonly property color surface: config.surface
    readonly property color border:  config.border
    readonly property color fg:      config.fg
    readonly property color accent:  config.accent
    readonly property color warn:    config.warn
    readonly property color bad:     config.bad
    readonly property string font:   "monospace"

    property string firstUser: ""
    readonly property string user: userModel.lastUser || firstUser
    property bool failed: false
    property bool busy: false
    property date now: new Date()

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

    Backdrop {
        anchors.fill: parent
        colors: config
        now: root.now
        font: root.font

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
