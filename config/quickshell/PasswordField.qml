import QtQuick

// Password box with caps indicator and "denied" line, shared by the sddm
// theme and the lock screen. Plain QtQuick only, like Backdrop.qml.
Column {
    id: root

    required property var colors // colors.json contents
    property string font: "monospace"
    property bool busy: false
    property bool capsLock: false
    property bool failed: false

    signal submitted(string password)

    // after a failed attempt: clear, mark failed, and shake
    function reject() {
        failed = true;
        password.text = "";
        shake.restart();
    }

    function takeFocus() {
        password.forceActiveFocus();
    }

    Rectangle {
        id: field
        anchors.horizontalCenter: parent.horizontalCenter
        width: 320
        height: 36
        color: root.colors.surface
        border.width: 1
        border.color: root.failed ? root.colors.bad
            : password.activeFocus ? root.colors.accent : root.colors.border

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
            color: root.colors.fg
            selectionColor: root.colors.accent
            font.family: root.font
            font.pixelSize: 12
            onTextEdited: root.failed = false
            onAccepted: root.submitted(text)
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
            text: root.capsLock ? "caps" : ""
            color: root.colors.warn
            font.family: root.font
            font.pixelSize: 12
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        topPadding: 10
        text: "denied"
        color: root.colors.bad
        opacity: root.failed ? 1 : 0
        font.family: root.font
        font.pixelSize: 12
    }
}
