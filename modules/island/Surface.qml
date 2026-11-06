pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.state
import qs.themes

// The pill. One interruptible progress animation (hyprism pattern) moves {width, height, y} between
// modes; a mode change mid-morph starts from the current values, never from the previous target.
StyledRect {
    id: root

    required property string screenName
    property real fromWidth: root.targetWidth
    property real fromHeight: root.targetHeight
    property real fromY: root.targetY
    property real progress: 1
    property bool expanding: true
    // The last OSD kind, kept while the OSD fades out so its icon doesn't flip to brightness.
    property string osdKind: "volume"
    readonly property bool fullscreen: Hypr.fullscreen(root.screenName)
    readonly property string restMode: root.fullscreen ? "hidden" : "rest"
    // Panels (island sections and the launcher) win over temporary modes, on their own screen only.
    readonly property bool knownPanel: Visibility.expanded || Visibility.panel === "launcher"
    readonly property bool panelHere: root.knownPanel && Visibility.screen === root.screenName
    readonly property string temporaryOrRest: Visibility.temporary !== "" ? Visibility.temporary : root.restMode
    readonly property string mode: root.panelHere ? Visibility.panel : root.temporaryOrRest
    readonly property real targetWidth: root.widthFor(root.mode)
    readonly property real targetHeight: root.heightFor(root.mode)
    readonly property real targetY: root.mode === "hidden" ? -Appearance.island.height : Appearance.island.margin
    readonly property color normalOutline: Qt.alpha(Colors.outlineVariant, Appearance.island.outlineOpacity)
    readonly property color alertOutline: Qt.alpha(Colors.error, Appearance.island.alertOutlineOpacity)
    // Island.qml raises the window to Overlay only over a true fullscreen window, while something shows
    // or the pill is still moving; on a normal workspace Top is already above every window.
    readonly property bool elevated: root.fullscreen && (root.mode !== "hidden" || root.morphing)
    // False while the pill morphs; Island.qml ignores a focus-grab clear that arrives before it settles.
    readonly property bool morphing: grow.running || shrink.running
    readonly property int morphDuration: root.expanding ? grow.duration : shrink.duration
    readonly property bool settled: !root.morphing

    function isTransient(mode: string): bool {
        return mode !== "rest" && mode !== "hidden";
    }

    // Size table: one entry per mode. The banner's height follows its content.
    function widthFor(mode: string): real {
        if (mode === "rest")
            return Math.min(restLayer.implicitWidth + 2 * Appearance.island.padding, Appearance.island.maxWidth);
        if (mode === "hidden")
            return Appearance.island.hiddenWidth;
        if (mode === "notification")
            return Appearance.island.notification.width;
        if (mode === "launcher")
            return Appearance.island.launcher.width;
        if (Visibility.isSection(mode))
            return root.expandedWidth(mode);
        return mode === "music" ? Appearance.island.music.width : Appearance.island.osd.width;
    }

    function expandedWidth(mode: string): real {
        const expanded = Appearance.island.expanded;
        return Visibility.tabs.includes(mode) ? expanded.tabWidth : expanded.sectionWidth;
    }

    function heightFor(mode: string): real {
        if (mode === "rest" || mode === "hidden")
            return Appearance.island.height;
        if (mode === "notification")
            return notificationLayer.implicitHeight;
        // Follows the result count; the layer loads as the morph starts, and the target updates live.
        if (mode === "launcher")
            return launcherLayer.implicitHeight + 2 * Appearance.island.launcher.padding;
        // Each section reports its own height; the target follows it live, also on a section change.
        if (Visibility.isSection(mode))
            return expandedLayer.implicitHeight + 2 * Appearance.island.expanded.padding;
        return mode === "music" ? Appearance.island.music.height : Appearance.island.osd.height;
    }

    // Scrolling on the OSD keeps adjusting what it shows; the resting view's scroll areas are hidden by then.
    function scrollOsd(step: int): void {
        if (root.osdKind === "volume")
            step < 0 ? Audio.up() : Audio.down();
        else
            step < 0 ? Brightness.up() : Brightness.down();
    }

    function retarget(): void {
        const width = root.width;
        const height = root.height;
        const y = root.y;
        // Growing gets the overshoot, shrinking doesn't (ISLAND.md "Motion"), whatever the modes are. The
        // target bindings can still hold the old mode here, so the new size comes from the mode itself.
        root.expanding = root.widthFor(root.mode) * root.heightFor(root.mode) > width * height;
        if (root.mode === "volume" || root.mode === "brightness")
            root.osdKind = root.mode;
        root.fromWidth = width;
        root.fromHeight = height;
        root.fromY = y;
        root.progress = 0;
        grow.stop();
        shrink.stop();
        (root.expanding ? grow : shrink).restart();
    }

    width: root.fromWidth + (root.targetWidth - root.fromWidth) * root.progress
    height: root.fromHeight + (root.targetHeight - root.fromHeight) * root.progress
    y: root.fromY + (root.targetY - root.fromY) * root.progress
    radius: Math.min(height / 2, Appearance.island.cornerRadius)
    color: Colors.island
    border.width: Appearance.island.outlineWidth
    border.color: Battery.low ? root.alertOutline : root.normalOutline
    clip: true
    onModeChanged: root.retarget()

    // Background, clock or date open the overview; icons with their own TapHandler take the click first.
    TapHandler {
        enabled: root.mode === "rest"
        onTapped: Visibility.openByPointer("overview", root.screenName)
    }

    // Two animations, one per curve: setting easing.bezierCurve switches an easing to BezierSpline, so a
    // single animation with both settings never overshoots.
    NumberAnimation {
        id: grow

        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Appearance.anim.scaled(Appearance.anim.islandExpand)
        easing.type: Easing.OutBack
        easing.overshoot: Appearance.anim.islandOvershoot
    }

    NumberAnimation {
        id: shrink

        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Appearance.anim.scaled(Appearance.anim.islandCollapse)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.standard
    }

    ModeLayer {
        id: restLayer

        anchors.centerIn: parent
        height: Appearance.island.height
        shown: root.mode === "rest"
        persistent: true
        fadeInDelay: root.morphDuration * Appearance.anim.islandFadeInAt
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
        fadeInDelay: root.morphDuration * Appearance.anim.islandFadeInAt
        sourceComponent: Component {
            OsdView {
                kind: root.osdKind
            }
        }
    }

    ModeLayer {
        anchors.centerIn: parent
        shown: root.mode === "mic"
        fadeInDelay: root.morphDuration * Appearance.anim.islandFadeInAt
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
        fadeInDelay: root.morphDuration * Appearance.anim.islandFadeInAt
        sourceComponent: Component {
            NotificationView {}
        }
    }

    ModeLayer {
        anchors.centerIn: parent
        width: Appearance.island.music.width - 2 * Appearance.island.music.padding
        height: Appearance.island.music.height
        shown: root.mode === "music"
        fadeInDelay: root.morphDuration * Appearance.anim.islandFadeInAt
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
        fadeInDelay: root.morphDuration * Appearance.anim.islandFadeInAt
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
        width: root.expandedWidth(root.mode) - 2 * Appearance.island.expanded.padding
        shown: Visibility.isSection(root.mode)
        fadeInDelay: root.morphDuration * Appearance.anim.islandFadeInAt
        sourceComponent: Component {
            Expanded {
                screenName: root.screenName
            }
        }
    }

    WheelArea {
        anchors.fill: parent
        enabled: root.mode === "volume" || root.mode === "brightness"
        onStepped: step => root.scrollOsd(step)
    }
}
