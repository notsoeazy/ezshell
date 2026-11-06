pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.state
import qs.themes

// Capture section: Screenshot and Record, each by Region, Window or Screen, and a sound switch. Arrows move,
// Enter or a click picks; the island collapses first and the capture waits for it (Capture.settle), so the
// island isn't in the picture. While a recording runs, the Record row is a single Stop card.
ColumnLayout {
    id: root

    readonly property list<string> modes: ["region", "window", "monitor"]
    readonly property list<string> labels: ["Region", "Window", "Screen"]
    readonly property list<string> icons: ["screenshot_region", "select_window", "screenshot_monitor"]
    // 0-2 screenshot cards, 3-5 record cards (or 3, Stop, while recording).
    property int selected: 0
    readonly property int count: Capture.recording ? 4 : 6

    function pick(index: int): void {
        Visibility.close();
        if (index >= 3 && Capture.recording)
            Capture.stop();
        else if (index >= 3)
            Capture.recordIn(root.modes[index - 3], Capture.settle);
        else
            Capture.screenshotIn(root.modes[index], Capture.settle);
    }

    function handleKey(event: KeyEvent): void {
        const row = root.selected >= 3 ? 1 : 0;
        if (event.key === Qt.Key_Right)
            root.selected = Math.min(root.selected + 1, row === 0 ? 2 : root.count - 1);
        else if (event.key === Qt.Key_Left)
            root.selected = Math.max(root.selected - 1, row === 0 ? 0 : 3);
        else if (event.key === Qt.Key_Down)
            root.selected = Math.min(root.selected + 3, root.count - 1);
        else if (event.key === Qt.Key_Up)
            root.selected = root.selected >= 3 ? Math.min(root.selected - 3, 2) : root.selected;
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.pick(root.selected);
        else
            return;
        event.accepted = true;
    }

    spacing: Appearance.island.expanded.gap
    focus: true
    Keys.onPressed: event => root.handleKey(event)
    Component.onCompleted: root.forceActiveFocus()
    onCountChanged: root.selected = Math.min(root.selected, root.count - 1)

    component Card: StyledRect {
        id: card

        required property int slot
        required property string label
        required property string icon
        readonly property bool current: card.slot === root.selected

        Layout.fillWidth: true
        implicitHeight: Appearance.island.capture.card
        radius: Appearance.island.expanded.cardRadius
        color: card.current ? Colors.surfaceContainerHighest : Colors.surfaceContainer
        border.width: card.current ? Appearance.settings.selectedBorder : 0
        border.color: Colors.primary

        Behavior on color {
            CAnim {}
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: card.icon
                size: Appearance.island.expanded.iconBox
                color: card.current ? Colors.primary : Colors.surfaceFg
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: card.label
                font.weight: Font.Medium
            }
        }

        HoverHandler {
            id: hover

            onHoveredChanged: {
                if (hover.hovered)
                    root.selected = card.slot;
            }
        }

        TapHandler {
            onTapped: root.pick(card.slot)
        }
    }

    component RowTitle: StyledText {
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
        font.weight: Font.Medium
    }

    RowTitle {
        text: "Screenshot · saved and copied"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.island.expanded.gap

        Repeater {
            model: 3

            Card {
                required property int modelData

                slot: modelData
                label: root.labels[modelData]
                icon: root.icons[modelData]
            }
        }
    }

    RowTitle {
        text: Capture.recording ? "Recording" : `Record${Config.capture.audio ? " · with sound" : ""}`
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.island.expanded.gap

        Repeater {
            model: Capture.recording ? 0 : 3

            Card {
                required property int modelData

                slot: 3 + modelData
                label: root.labels[modelData]
                icon: root.icons[modelData]
            }
        }

        Card {
            visible: Capture.recording
            slot: 3
            label: "Stop recording"
            icon: "stop_circle"
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: "Record sound"
        }

        StyledSwitch {
            checked: Config.capture.audio
            onToggled: checked => Capture.setAudio(checked)
        }
    }
}
