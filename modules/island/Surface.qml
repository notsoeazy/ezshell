pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services
import qs.state
import qs.themes

// The pill. One interruptible progress animation (hyprism pattern) moves {width, height, y} between
// modes; a mode change mid-morph starts from the current values, never from the previous target.
StyledRect {
    id: root

    required property string screenName
    // Monitor that shows the polkit prompt (Island.qml picks the focused one when a request arrives).
    required property string authScreen
    property real fromWidth: root.target.width
    property real fromHeight: root.target.height
    property real fromY: root.targetY
    property real progress: 1
    property bool expanding: true
    // The last OSD kind, kept while the OSD fades out so its icon doesn't flip to brightness.
    property string osdKind: "volume"
    readonly property bool fullscreen: Hypr.fullscreen(root.screenName)
    readonly property string restMode: root.fullscreen || Visibility.islandHidden ? "hidden" : "rest"
    // Panels (island sections and the launcher) win over temporary modes, on their own screen only.
    readonly property bool knownPanel: Visibility.expanded || ["launcher", "switcher"].includes(Visibility.panel)
    readonly property bool panelHere: root.knownPanel && Visibility.screen === root.screenName
    // The hover peek (docs/ISLAND-R1.md) only replaces the plain resting pill: not under a fullscreen
    // window or while hidden, and anything else showing wins over it.
    readonly property bool peekHere: Visibility.peekScreen === root.screenName && root.restMode === "rest"
    readonly property string idleMode: root.peekHere ? "peek" : root.restMode
    readonly property string temporaryOrRest: Visibility.temporary !== "" ? Visibility.temporary : root.idleMode
    readonly property string underlying: root.panelHere ? Visibility.panel : root.temporaryOrRest
    // Polkit outranks everything, panels included. Visibility isn't touched, so when the prompt ends the
    // island goes back to whatever was open underneath.
    readonly property bool authHere: Polkit.active && root.authScreen === root.screenName
    readonly property string mode: root.authHere ? "polkit" : root.underlying
    readonly property size target: root.sizeFor(root.mode)
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

    // Mode table: the pill's size in each mode. A new mode is one case. Sizes that follow content read
    // the layer live, so the target tracks it (banner text, launcher results, section height).
    function sizeFor(mode: string): size {
        const island = Appearance.island;
        if (Visibility.isSection(mode))
            return Qt.size(root.sectionWidth(mode), layers.expandedHeight + 2 * island.expanded.padding);
        switch (mode) {
        case "rest":
            return Qt.size(Math.min(layers.restWidth + 2 * island.padding, island.maxWidth), island.height);
        case "hidden":
            return Qt.size(island.hiddenWidth, island.height);
        case "notification":
            return Qt.size(island.notification.width, layers.notificationHeight);
        case "launcher":
            return Qt.size(island.launcher.width, layers.launcherHeight + 2 * island.launcher.padding);
        case "peek":
            return Qt.size(Math.max(layers.restWidth + 2 * island.padding, island.peek.width), island.peek.height);
        case "message":
            return root.messageSize();
        case "polkit":
            return Qt.size(island.polkit.width, layers.polkitHeight + 2 * island.polkit.padding);
        case "music":
            return Qt.size(root.musicWidth(), island.height);
        case "switcher":
            return root.padded(layers.switcherWidth, layers.switcherHeight, island.switcher.padding);
        default:
            // volume, brightness
            return Qt.size(island.osd.width, island.osd.height);
        }
    }

    function padded(width: real, height: real, padding: real): size {
        return Qt.size(width + 2 * padding, height + 2 * padding);
    }

    // As wide as the now-playing content, within its bounds.
    function musicWidth(): real {
        const music = Appearance.island.music;
        return Math.min(Math.max(layers.musicWidth + 2 * Appearance.island.padding, music.minWidth), music.maxWidth);
    }

    // As wide as the message (within its bounds), and at least as tall as the OSD.
    function messageSize(): size {
        const message = Appearance.island.message;
        const width = layers.messageWidth + 2 * message.padding;
        const height = Math.max(Appearance.island.osd.height, layers.messageHeight + 2 * message.padding);
        return Qt.size(Math.min(Math.max(width, message.minWidth), message.maxWidth), height);
    }

    // Each tab has its own width (docs/ISLAND-R1.md); detail sections and capture are narrow; wallpapers
    // is dashboard-wide.
    function sectionWidth(mode: string): real {
        const dashboard = Appearance.island.dashboard;
        const tabs = {
            control: dashboard.controlWidth,
            media: dashboard.mediaWidth,
            system: dashboard.systemWidth,
            weather: dashboard.weatherWidth,
            calendar: dashboard.calendarWidth
        };
        if (tabs[mode] !== undefined)
            return tabs[mode];
        const expanded = Appearance.island.expanded;
        return Visibility.details.includes(mode) || mode === "capture" ? expanded.sectionWidth : expanded.tabWidth;
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
        const next = root.sizeFor(root.mode);
        root.expanding = next.width * next.height > width * height;
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

    width: root.fromWidth + (root.target.width - root.fromWidth) * root.progress
    height: root.fromHeight + (root.target.height - root.fromHeight) * root.progress
    y: root.fromY + (root.targetY - root.fromY) * root.progress
    radius: Math.min(height / 2, root.peekHere ? Appearance.island.peek.radius : Appearance.island.cornerRadius)
    color: Colors.island
    border.width: Appearance.island.outlineWidth
    border.color: Battery.low ? root.alertOutline : root.normalOutline
    clip: true
    onModeChanged: root.retarget()

    // Background, clock or date open Control; icons with their own TapHandler take the click first.
    TapHandler {
        id: tap

        enabled: root.mode === "rest" || root.mode === "peek"
        onTapped: Visibility.openByPointer("control", root.screenName)
    }

    // Hover peek: opens after a short hover on the resting pill, closes a little after the pointer leaves
    // (re-entering cancels that). Not while a button is held, and never over another mode. UI-only timers.
    HoverHandler {
        id: hover

        enabled: Config.island.hoverPeek
        onHoveredChanged: {
            if (hover.hovered) {
                closePeek.stop();
                if (root.mode === "rest" && !tap.pressed)
                    openPeek.restart();
            } else {
                openPeek.stop();
                if (Visibility.peekScreen === root.screenName)
                    closePeek.restart();
            }
        }
    }

    Timer {
        id: openPeek

        interval: Appearance.island.peek.openDelay
        onTriggered: {
            if (hover.hovered && root.mode === "rest" && !tap.pressed)
                Visibility.peekScreen = root.screenName;
        }
    }

    Timer {
        id: closePeek

        interval: Appearance.island.peek.closeDelay
        onTriggered: {
            if (Visibility.peekScreen === root.screenName)
                Visibility.peekScreen = "";
        }
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

    ModeLayers {
        id: layers

        anchors.fill: parent
        mode: root.mode
        screenName: root.screenName
        osdKind: root.osdKind
        fadeInDelay: root.morphDuration * Appearance.anim.islandFadeInAt
        sectionWidth: root.sectionWidth(root.mode)
        // While the prompt covers a panel, the panel stays loaded so its text and page survive.
        held: root.mode === "polkit" ? root.underlying : ""
    }

    WheelArea {
        anchors.fill: parent
        enabled: root.mode === "volume" || root.mode === "brightness"
        onStepped: step => root.scrollOsd(step)
    }
}
