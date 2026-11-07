pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.services
import qs.themes

// The notification center at the bottom of the Control tab (docs/ISLAND-R1.md): newest first, a click runs
// the default action, ✕ (on hover) dismisses with a slide-out, Clear all asks for a second click.
ColumnLayout {
    id: root

    // True after the first click on Clear all; any change to the list cancels it.
    property bool clearArmed: false

    spacing: Appearance.island.control.gap

    Connections {
        function onCountChanged(): void {
            root.clearArmed = false;
        }

        target: Notifs
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            text: "Notifications"
            font.pixelSize: Appearance.island.control.title
            font.weight: Font.DemiBold
        }

        StyledText {
            visible: Notifs.count > 0
            text: `${Notifs.count}`
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.normal
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            visible: Notifs.count > 0
            text: root.clearArmed ? "Click again to clear" : "Clear all"
            color: root.clearArmed ? Colors.error : Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
            font.weight: Font.Medium

            TapHandler {
                margin: Appearance.spacing.small
                onTapped: {
                    if (root.clearArmed)
                        Notifs.clear();
                    root.clearArmed = !root.clearArmed;
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: Notifs.dnd
        text: "Do not disturb is on"
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
    }

    // Empty: a small fixed-height "All caught up".
    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Appearance.island.control.emptyHeight
        visible: Notifs.count === 0
        spacing: Appearance.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "notifications"
            color: Colors.surfaceVariantFg
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "All caught up"
            font.pixelSize: Appearance.island.control.title
            color: Colors.surfaceVariantFg
        }
    }

    Repeater {
        model: ScriptModel {
            values: [...Notifs.list].reverse()
        }

        StyledRect {
            id: item

            required property Notification modelData
            readonly property string image: item.modelData?.image ?? ""
            readonly property string appIcon: item.modelData?.appIcon ?? ""
            // "Discord · 2m"
            readonly property string source: [item.modelData?.appName ?? "", item.age].filter(t => t !== "").join(" · ")
            readonly property string age: Notifs.age(item.modelData, Time.date)
            // 1 → 0 while leaving: the item's height follows it, so the list closes the gap.
            property real collapse: 1

            // Slides out, closes the gap, then goes from the list.
            function dismiss(): void {
                leaving.start();
            }

            Layout.fillWidth: true
            Layout.preferredHeight: (content.implicitHeight + 2 * Appearance.island.control.cardPadding) * item.collapse
            radius: Appearance.island.control.cardRadius
            color: Colors.surfaceContainerHigh
            clip: true

            SequentialAnimation {
                id: leaving

                ParallelAnimation {
                    Anim {
                        target: content
                        property: "x"
                        to: item.width
                    }

                    Anim {
                        target: item
                        property: "opacity"
                        to: 0
                    }
                }

                Anim {
                    target: item
                    property: "collapse"
                    to: 0
                }

                ScriptAction {
                    script: Notifs.dismiss(item.modelData)
                }
            }

            HoverHandler {
                id: hover
            }

            TapHandler {
                onTapped: Notifs.activate(item.modelData)
            }

            RowLayout {
                id: content

                width: parent.width - 2 * Appearance.island.control.cardSidePadding
                x: Appearance.island.control.cardSidePadding
                y: Appearance.island.control.cardPadding
                spacing: Appearance.island.control.gap + Appearance.spacing.small

                ClippingRectangle {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: Appearance.island.control.notifIcon
                    implicitHeight: Appearance.island.control.notifIcon
                    radius: Appearance.island.control.notifIconRadius
                    color: Colors.surfaceContainerHighest

                    IconImage {
                        anchors.fill: parent
                        visible: item.image === ""
                        source: Quickshell.iconPath(item.appIcon, "dialog-information")
                    }

                    Image {
                        anchors.fill: parent
                        visible: item.image !== ""
                        source: item.image
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: Appearance.island.control.notifIcon
                        sourceSize.height: Appearance.island.control.notifIcon
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: item.source
                        elide: Text.ElideRight
                        color: Colors.surfaceVariantFg
                        font.pixelSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: item.modelData?.summary ?? ""
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.island.control.title
                        font.weight: Font.Medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: item.modelData?.body ?? ""
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Colors.surfaceVariantFg
                        font.pixelSize: Appearance.font.size.normal
                    }
                }

                MaterialIcon {
                    Layout.alignment: Qt.AlignTop
                    opacity: hover.hovered ? 1 : 0
                    text: "close"
                    color: Colors.surfaceVariantFg

                    Behavior on opacity {
                        Anim {}
                    }

                    // Exclusive grab on press, so the item's TapHandler doesn't also run the default action.
                    TapHandler {
                        margin: Appearance.spacing.small
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: item.dismiss()
                    }
                }
            }
        }
    }
}
