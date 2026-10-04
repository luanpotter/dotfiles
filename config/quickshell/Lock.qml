pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

// Lock screen: same Backdrop + PasswordField as the sddm theme, on every
// monitor. Locked through ext-session-lock, so if this shell dies the
// session stays locked. Trigger with `qs ipc call lock lock`.
Scope {
    id: root

    property bool locked: false
    property string password: ""

    signal failed

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.locked = true;
        }
    }

    function tryUnlock(password) {
        if (pam.active)
            return;
        root.password = password;
        pam.start();
    }

    // the "login" stack, same as a console login; answers the password prompt
    PamContext {
        id: pam

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            root.password = "";
            if (result === PamResult.Success)
                root.locked = false;
            else
                root.failed();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.locked
    }

    // caps lock isn't exposed to Qt, but Hyprland reports it per keyboard;
    // only polled while locked
    property bool capsLock: false

    Process {
        id: caps
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const main = JSON.parse(text).keyboards.find(k => k.main);
                root.capsLock = main?.capsLock ?? false;
            }
        }
    }

    Timer {
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: root.locked
        onTriggered: caps.running = true
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: Theme.bg

            Backdrop {
                anchors.fill: parent
                colors: Theme.colors
                now: clock.date
                font: Theme.font

                PasswordField {
                    id: field
                    anchors.horizontalCenter: parent.horizontalCenter
                    colors: Theme.colors
                    font: Theme.font
                    busy: pam.active
                    capsLock: root.capsLock
                    onSubmitted: password => {
                        field.failed = false;
                        root.tryUnlock(password);
                    }
                }
            }

            Connections {
                target: root
                function onFailed() {
                    field.reject();
                }
            }

            // clicking anywhere returns focus to the field
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: field.takeFocus()
            }
        }
    }
}
