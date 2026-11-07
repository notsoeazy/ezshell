import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.state
import qs.themes

// Trailing indicators, highest priority first: recording / screen share, mic and camera, keyboard layout,
// game mode, keep awake, DND, unread badge (docs/ISLAND.md "Default island variations"). No timers; workspaces and
// date are untouched.
RowLayout {
    id: root

    required property string screenName
    // Lowest priority goes first when space is tight: the unread count becomes a plain dot.
    property bool compactBadge: false
    // Width given back by compactBadge, measured from the full badge so it doesn't depend on the state.
    readonly property real badgeSaving: Notifs.count > 0 ? fullBadge.pill - Appearance.island.indicatorDot : 0

    spacing: Appearance.spacing.normal

    component Dot: StyledRect {
        implicitWidth: Appearance.island.indicatorDot
        implicitHeight: Appearance.island.indicatorDot
        radius: height / 2
    }

    // Recording or screen share: error dot + an icon. Hyprland reports shares; ezshell's own recordings
    // (gpu-screen-recorder, invisible to Hyprland) come from Capture, and a click stops them. Otherwise the
    // handler only keeps the click from expanding the island.
    RowLayout {
        opacity: Hypr.screenSharing || Capture.recording ? 1 : 0
        // Fades out before leaving the layout, so the balance-rule width change follows the fade.
        visible: opacity > 0

        Behavior on opacity {
            Anim {}
        }
        spacing: Appearance.spacing.small

        Dot {
            color: Colors.error
        }

        MaterialIcon {
            text: Capture.recording ? "stop_circle" : "screen_share"
            color: Colors.error
        }

        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: Capture.stop()
        }
    }

    // Mic or camera in use: warning dot + mic and/or videocam. Opens the audio section, which names the apps.
    RowLayout {
        opacity: (Audio.micInUse || Camera.inUse) ? 1 : 0
        // Fades out before leaving the layout, so the balance-rule width change follows the fade.
        visible: opacity > 0

        Behavior on opacity {
            Anim {}
        }
        spacing: Appearance.spacing.small

        Dot {
            color: Colors.warning
        }

        MaterialIcon {
            visible: Audio.micInUse
            text: "mic"
            fill: 1
            color: Colors.warning
        }

        MaterialIcon {
            visible: Camera.inUse
            text: "videocam"
            fill: 1
            color: Colors.warning
        }

        TapHandler {
            margin: Appearance.spacing.small
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: Visibility.openByPointer("audio", root.screenName)
        }
    }

    // The keyboard layout, only when more than one is configured.
    StyledText {
        opacity: Keyboard.multiple ? 1 : 0
        // Fades out before leaving the layout, so the balance-rule width change follows the fade.
        visible: opacity > 0

        Behavior on opacity {
            Anim {}
        }
        text: Keyboard.code
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
        font.weight: Font.DemiBold
    }

    // Game mode: a click turns it off.
    MaterialIcon {
        opacity: GameMode.active ? 1 : 0
        // Fades out before leaving the layout, so the balance-rule width change follows the fade.
        visible: opacity > 0

        Behavior on opacity {
            Anim {}
        }
        text: "sports_esports"
        fill: 1
        color: Colors.primary

        TapHandler {
            margin: Appearance.spacing.small
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: GameMode.off()
        }
    }

    // Keep awake: a click turns it off.
    MaterialIcon {
        opacity: Idle.inhibited ? 1 : 0
        // Fades out before leaving the layout, so the balance-rule width change follows the fade.
        visible: opacity > 0

        Behavior on opacity {
            Anim {}
        }
        text: "coffee"
        fill: 1
        color: Colors.surfaceVariantFg

        TapHandler {
            margin: Appearance.spacing.small
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: Idle.setInhibited(false)
        }
    }

    MaterialIcon {
        opacity: Notifs.dnd ? 1 : 0
        // Fades out before leaving the layout, so the balance-rule width change follows the fade.
        visible: opacity > 0

        Behavior on opacity {
            Anim {}
        }
        text: "do_not_disturb_on"
        color: Colors.surfaceVariantFg
    }

    StyledRect {
        opacity: (Notifs.count > 0) ? 1 : 0
        // Fades out before leaving the layout, so the balance-rule width change follows the fade.
        visible: opacity > 0

        Behavior on opacity {
            Anim {}
        }
        implicitWidth: root.compactBadge ? Appearance.island.indicatorDot : fullBadge.pill
        implicitHeight: root.compactBadge ? Appearance.island.indicatorDot : Appearance.island.badge
        radius: height / 2
        color: root.compactBadge ? Colors.primary : Colors.primaryContainer

        // Measures the full badge; drawn only when not compact.
        StyledText {
            id: fullBadge

            readonly property real padded: fullBadge.contentWidth + 2 * Appearance.spacing.small
            readonly property real pill: Math.max(Appearance.island.badge, fullBadge.padded)

            anchors.centerIn: parent
            visible: !root.compactBadge
            text: `${Notifs.count}`
            color: Colors.primaryContainerFg
            font.pixelSize: Appearance.font.size.small
            font.weight: Font.DemiBold
        }

        TapHandler {
            margin: Appearance.spacing.small
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: Visibility.openByPointer("notifications", root.screenName)
        }
    }
}
