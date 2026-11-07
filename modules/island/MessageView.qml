pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.state
import qs.themes

// The island's one message mode (Visibility.message): mic mute, capture feedback, task results and `osd show`
// from scripts. Fields, all optional but text:
//   icon       Material Symbols name;  tone: normal | primary | success | error (icon and dot color)
//   dot        "pulse" or "steady": a status dot instead of the icon
//   text       first line;  subtitle: second line;  hint: small text on the right
//   thumbnail  image file, shown on the left (it pops in);  swatch: a color, shown as a round chip on the left
//   progress   0-1 for a bar under the text, -1 for a pulsing one
RowLayout {
    id: root

    readonly property var message: Visibility.message
    readonly property color toneColor: root.colorFor(root.message.tone ?? "normal")
    readonly property bool hasProgress: root.message.progress !== undefined

    function colorFor(tone: string): color {
        if (tone === "error")
            return Colors.error;
        if (tone === "success")
            return Colors.success;
        return tone === "primary" ? Colors.primary : Colors.surfaceFg;
    }

    spacing: Appearance.island.message.gap

    // Pops in, so a screenshot reads as taken even before the text does.
    ClippingRectangle {
        id: thumb

        visible: (root.message.thumbnail ?? "") !== ""
        scale: Appearance.island.message.popFrom
        Component.onCompleted: thumb.scale = 1
        implicitWidth: Appearance.island.message.thumbWidth
        implicitHeight: Appearance.island.message.thumbHeight
        radius: Appearance.rounding.small
        color: Colors.surfaceContainerHigh

        Behavior on scale {
            Anim {
                duration: Appearance.anim.scaled(Appearance.anim.islandExpand)
                easing.type: Easing.OutBack
            }
        }

        Image {
            anchors.fill: parent
            source: thumb.visible ? `file://${root.message.thumbnail}` : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Appearance.island.message.thumbWidth
            sourceSize.height: Appearance.island.message.thumbHeight
        }
    }

    StyledRect {
        visible: root.message.swatch !== undefined
        implicitWidth: Appearance.island.message.swatch
        implicitHeight: Appearance.island.message.swatch
        radius: height / 2
        color: root.message.swatch ?? Colors.transparent
        border.width: Appearance.island.outlineWidth
        border.color: Colors.outlineVariant
    }

    StyledRect {
        visible: root.message.dot !== undefined
        implicitWidth: Appearance.island.indicatorDot
        implicitHeight: Appearance.island.indicatorDot
        radius: height / 2
        color: Colors.error

        SequentialAnimation on opacity {
            running: root.message.dot === "pulse"
            loops: Animation.Infinite
            alwaysRunToEnd: true

            Anim {
                to: Appearance.island.dimmedOpacity
                duration: Appearance.anim.scaled(Appearance.anim.pulse)
            }

            Anim {
                to: 1
                duration: Appearance.anim.scaled(Appearance.anim.pulse)
            }
        }
    }

    MaterialIcon {
        visible: (root.message.icon ?? "") !== "" && root.message.dot === undefined && root.message.swatch === undefined
        text: root.message.icon ?? ""
        size: Appearance.island.osd.icon
        color: root.toneColor
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: root.message.text ?? ""
            elide: Text.ElideRight
            font.weight: Font.Medium
        }

        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.message.subtitle ?? ""
            elide: Text.ElideRight
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }

        LevelBar {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            implicitHeight: Appearance.island.osd.trackHeight
            visible: root.hasProgress
            value: root.message.progress >= 0 ? root.message.progress : 1

            SequentialAnimation on opacity {
                running: root.hasProgress && root.message.progress < 0
                loops: Animation.Infinite
                alwaysRunToEnd: true

                Anim {
                    to: Appearance.island.dimmedOpacity
                    duration: Appearance.anim.scaled(Appearance.anim.pulse)
                }

                Anim {
                    to: 1
                    duration: Appearance.anim.scaled(Appearance.anim.pulse)
                }
            }
        }
    }

    StyledText {
        visible: text !== ""
        text: root.message.hint ?? ""
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
    }
}
