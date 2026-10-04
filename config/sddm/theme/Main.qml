import QtQuick

// Same screen as the quickshell wallpaper: Backdrop.qml, PasswordField.qml
// and arch.svg are copied in at install, and theme.conf (read via `config`)
// is generated from colors.json. See os/arch/core.yaml.
Item {
    id: root

    readonly property string font: "monospace"

    property string firstUser: ""
    readonly property string user: userModel.lastUser || firstUser
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
            field.reject();
        }
    }

    function login(password) {
        if (busy || !user)
            return;
        busy = true;
        field.failed = false;
        sddm.login(user, password, sessionModel.lastIndex);
    }

    Backdrop {
        anchors.fill: parent
        colors: config
        now: root.now
        font: root.font

        PasswordField {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            colors: config
            font: root.font
            busy: root.busy
            capsLock: keyboard.capsLock
            onSubmitted: password => root.login(password)
        }
    }

    // clicking anywhere returns focus to the field
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: field.takeFocus()
    }
}
