import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.state
import qs.themes
import qs.utils

// Control tab (docs/ISLAND-R1.md), the island's first tab: tiles and round buttons, the Sound and
// Display sliders, the media row while something plays, then the notification center. Taller than the
// island allows, it scrolls; `panels open notifications` scrolls it to the notification center.
Flickable {
    id: root

    required property string screenName

    function open(section: string): void {
        Visibility.openByPointer(section, root.screenName);
    }

    // As far down as the notification center's top, without scrolling past the end.
    function revealNotifications(): void {
        scroll.to = Math.max(0, Math.min(center.y, root.contentHeight - root.height));
        scroll.restart();
    }

    implicitHeight: Math.min(column.implicitHeight, Appearance.island.expanded.pageMaxHeight)
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    // Opened as "notifications": scroll once the layout has its heights.
    Component.onCompleted: {
        if (Visibility.reveal === "notifications")
            Qt.callLater(root.revealNotifications);
    }

    Connections {
        function onRevealRequestChanged(): void {
            if (Visibility.reveal === "notifications")
                Qt.callLater(root.revealNotifications);
        }

        target: Visibility
    }

    Anim {
        id: scroll

        target: root
        property: "contentY"
        duration: Appearance.anim.scaled(Appearance.anim.normal)
    }

    ColumnLayout {
        id: column

        width: root.width
        spacing: Appearance.island.control.gap

        QuickToggles {
            Layout.fillWidth: true
            screenName: root.screenName
        }

        ControlSlider {
            Layout.fillWidth: true
            label: "Sound"
            detail: Audio.label(Audio.sink)
            icon: Icons.volume(Audio.volume, Audio.muted)
            value: Audio.muted ? 0 : Audio.volume
            onMoved: value => Audio.set(value)
            onIconClicked: Audio.toggleMute()
            onOpened: root.open("audio")
        }

        ControlSlider {
            Layout.fillWidth: true
            visible: Brightness.available
            label: "Display"
            icon: Icons.brightness(Brightness.level)
            value: Brightness.level
            onMoved: value => Brightness.set(value)
            onOpened: root.open("display")
        }

        MediaRow {
            Layout.fillWidth: true
            screenName: root.screenName
        }

        NotificationCenter {
            id: center

            Layout.fillWidth: true
            Layout.topMargin: Appearance.island.control.gap
        }
    }
}
