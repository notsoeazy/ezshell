pragma ComponentBehavior: Bound

import QtQuick
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
    readonly property real restWidth: restLayer.implicitWidth
    readonly property real notificationHeight: notificationLayer.implicitHeight
    readonly property real launcherHeight: launcherLayer.implicitHeight
    readonly property real expandedHeight: expandedLayer.implicitHeight

    ModeLayer {
        id: restLayer

        anchors.centerIn: parent
        height: Appearance.island.height
        shown: root.mode === "rest"
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
        anchors.centerIn: parent
        shown: root.mode === "mic"
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            MicView {}
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
        anchors.centerIn: parent
        width: Appearance.island.music.width - 2 * Appearance.island.music.padding
        height: Appearance.island.music.height
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
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            LauncherView {}
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
        fadeInDelay: root.fadeInDelay
        sourceComponent: Component {
            Expanded {
                screenName: root.screenName
            }
        }
    }
}
