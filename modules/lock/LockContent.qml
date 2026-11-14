import QtQuick
import qs.config
import qs.theme
import qs.components
import qs.components.controls
import qs.services
import qs.modules.island.components

// What the lock screen shows: the wallpaper, the date and a large clock, and
// a password field that appears on the first key or click. Text is drawn in
// the dark scheme's colours whatever the theme, since it sits on a picture.
Item {
    id: root

    // Whether the clock starts at the island's clock and travels to its
    // place; otherwise it fades in where it stands.
    required property bool travels
    // False for the first frame and while leaving, so everything animates in
    // and out.
    property bool present
    readonly property bool settled: present && !Lock.leaving
    // 0: the clock is at the island. 1: it is in place.
    property real progress: settled ? 1 : 0
    // Whether the password field is showing.
    property bool awake
    readonly property bool asking: awake || field.text.length > 0 || Lock.message.length > 0
    // Sideways offset of the field while it shakes its head.
    property real shake

    Component.onCompleted: {
        present = true;
        field.focusInput();
    }

    Keys.onEscapePressed: {
        field.clear();
        awake = false;
    }

    Behavior on progress {
        Anim {
            style: Tokens.motion.spatialSlow
        }
    }

    Connections {
        function onFailed(): void {
            field.clear();
            field.focusInput();
            shaking.restart();
        }

        target: Lock
    }

    Image {
        anchors.fill: parent
        source: Wallpapers.current
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.dark.scrim
        opacity: root.settled ? 1 : 0

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effectsSlow
            }
        }
    }

    // A click anywhere asks for the password.
    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.awake = true;
            field.focusInput();
        }
    }

    Label {
        id: date

        anchors.horizontalCenter: parent.horizontalCenter
        y: clock.restY - clock.height / 2 - height
        text: Time.format("dddd, d MMMM")
        fontSize: Tokens.fontSize.xl
        color: Theme.dark.label
        opacity: root.settled ? 1 : 0

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effectsSlow
            }
        }
    }

    // The same component as the island's clock, so the two line up: it
    // starts at the island clock's size and place and grows into its own.
    Clock {
        id: clock

        readonly property real startScale: Tokens.fontSize.md / Tokens.lock.clockSize
        readonly property real startY: Config.border.thickness + Tokens.island.height / 2
        readonly property real restY: root.height * Tokens.lock.clockCenter
        readonly property real centerY: root.travels ? startY + (restY - startY) * root.progress : restY

        x: (parent.width - width) / 2
        y: centerY - height / 2
        fontSize: Tokens.lock.clockSize
        weight: Tokens.fontWeight.bold
        color: Theme.dark.label
        scale: root.travels ? startScale + (1 - startScale) * root.progress : 1
        opacity: root.travels ? 1 : Math.max(0, Math.min(1, root.progress))
    }

    Column {
        x: (parent.width - width) / 2 + root.shake
        y: parent.height * Tokens.lock.fieldCenter - field.height / 2
        spacing: Tokens.spacing.sm
        opacity: root.asking && root.settled ? 1 : 0

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effects
            }
        }

        // An opaque backing, so the field reads the same on any picture.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: field.implicitWidth
            implicitHeight: field.implicitHeight
            radius: field.radius
            color: Theme.color.surfaceRaised

            TextField {
                id: field

                anchors.fill: parent
                implicitWidth: Tokens.lock.fieldWidth
                size: Tokens.size.xl
                secure: true
                leadingIcon: "lock"
                placeholder: "Enter password"
                disabled: Lock.checking || Lock.leaving
                onAccepted: {
                    if (text.length > 0)
                        Lock.submit(text);
                    else
                        root.awake = true;
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Lock.checking ? "Checking…" : Lock.message
            fontSize: Tokens.fontSize.sm
            color: Theme.dark.label
        }
    }

    // Wrong password: the field shakes.
    SequentialAnimation {
        id: shaking

        Anim {
            target: root
            property: "shake"
            to: Tokens.spacing.md
            style: Tokens.motion.effectsFast
        }

        Anim {
            target: root
            property: "shake"
            to: -Tokens.spacing.md
            style: Tokens.motion.effectsFast
        }

        Anim {
            target: root
            property: "shake"
            to: 0
            style: Tokens.motion.spatialFast
        }
    }
}
