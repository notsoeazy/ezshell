pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.launcher
import qs.state
import qs.themes

// The content of every island mode, one ModeLayer each. Surface sizes the pill from the mode table and
// reads the content-driven sizes reported here.
Item {
    id: root

    required property string mode
    required property string screenName
    // The OSD kind to show; Surface keeps the last one while the OSD fades out.
    required property string osdKind
    required property int fadeInDelay
    required property real sectionWidth
    // The mode under the polkit prompt, kept loaded while hidden ("" otherwise).
    required property string held
    readonly property real restWidth: restLayer.implicitWidth
    readonly property real notificationHeight: notificationLayer.implicitHeight
    readonly property real launcherHeight: launcherLayer.implicitHeight
    readonly property real expandedHeight: expandedLayer.implicitHeight
    readonly property real polkitHeight: polkitLayer.implicitHeight
    readonly property real messageWidth: messageLayer.implicitWidth
    readonly property real messageHeight: messageLayer.implicitHeight
    readonly property real musicWidth: musicLayer.implicitWidth

    // Pinned to the top 44 px, so the peek's first line is this same layer (the clock never shifts). As
    // wide as the pill's live width, so while it grows into the peek the sides slide out with its edges;
    // never narrower than its content, so a shrinking morph doesn't squeeze the sides into the clock.
    ModeLayer {
        id: restLayer

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(restLayer.implicitWidth, parent.width - 2 * Appearance.island.padding)
        height: Appearance.island.height
        shown: root.mode === "rest" || root.mode === "peek"
        persistent: true
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            Default {
                screenName: root.screenName
            }
        }
    }

    ModeLayer {
        anchors.centerIn: parent
        width: Appearance.island.osd.width
        height: Appearance.island.osd.height
        shown: root.mode === "volume" || root.mode === "brightness"
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            OsdView {
                kind: root.osdKind
            }
        }
    }

    ModeLayer {
        id: notificationLayer

        anchors.centerIn: parent
        shown: root.mode === "notification"
        // Kept loaded so its height is known before the morph starts.
        persistent: true
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            NotificationView {}
        }
    }

    ModeLayer {
        id: musicLayer

        anchors.centerIn: parent
        // The pill's size is the content's implicit size (Surface.sizeFor), so this doesn't loop.
        width: Math.min(musicLayer.implicitWidth, Appearance.island.music.maxWidth - 2 * Appearance.island.padding)
        height: Appearance.island.height
        shown: root.mode === "music"
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            MusicView {}
        }
    }

    ModeLayer {
        id: launcherLayer

        // Pinned to the top so the search field stays put while the height follows the results.
        anchors.top: parent.top
        anchors.topMargin: Appearance.island.launcher.padding
        anchors.horizontalCenter: parent.horizontalCenter
        width: Appearance.island.launcher.width - 2 * Appearance.island.launcher.padding
        shown: root.mode === "launcher"
        persistent: root.held === "launcher"
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            Launcher {}
        }
    }

    ModeLayer {
        id: expandedLayer

        // Pinned to the top so the header stays put while the height follows the section.
        anchors.top: parent.top
        anchors.topMargin: Appearance.island.expanded.padding
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.sectionWidth - 2 * Appearance.island.expanded.padding
        shown: Visibility.isSection(root.mode)
        persistent: Visibility.isSection(root.held)
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            Expanded {
                screenName: root.screenName
            }
        }
    }

    ModeLayer {
        id: polkitLayer

        // Pinned to the top so the message stays put while the failure line comes and goes.
        anchors.top: parent.top
        anchors.topMargin: Appearance.island.polkit.padding
        anchors.horizontalCenter: parent.horizontalCenter
        width: Appearance.island.polkit.width - 2 * Appearance.island.polkit.padding
        shown: root.mode === "polkit"
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            PolkitView {}
        }
    }

    ModeLayer {
        id: messageLayer

        anchors.centerIn: parent
        // Its own width, centered in the pill; squeezed (texts elide) only when wider than the pill allows.
        // The message's size is its implicit size, so this doesn't loop.
        width: Math.min(messageLayer.implicitWidth, parent.width - 2 * Appearance.island.message.padding)
        shown: root.mode === "message"
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            MessageView {}
        }
    }

    // The peek's second line, right under the first.
    ModeLayer {
        anchors.top: parent.top
        anchors.topMargin: Appearance.island.height
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Appearance.island.padding
        anchors.rightMargin: Appearance.island.padding
        shown: root.mode === "peek"
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            PeekView {
                screenName: root.screenName
            }
        }
    }
}
