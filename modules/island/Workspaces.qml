pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.themes

RowLayout {
    id: root

    required property string screenName
    readonly property int active: Math.max(1, Hypr.activeWorkspace(root.screenName))
    readonly property int shown: Math.max(1, Config.workspaces.shown)
    readonly property int pageOffset: Math.floor((root.active - 1) / root.shown) * root.shown
    readonly property bool showNumbers: Config.workspaces.showNumbers

    spacing: Appearance.island.dotGap

    Repeater {
        model: root.shown

        StyledRect {
            id: dot

            required property int index
            readonly property int workspace: root.pageOffset + dot.index + 1
            readonly property bool current: root.active === dot.workspace
            readonly property int baseSize: root.showNumbers ? Appearance.island.badge : Appearance.island.dot
            readonly property int minW: Appearance.island.activeDot
            readonly property int labelW: dotLabel.implicitWidth + 2 * Appearance.spacing.small
            readonly property int activeWidth: root.showNumbers ? Math.max(dot.minW, dot.labelW) : dot.minW

            implicitWidth: dot.current ? dot.activeWidth : dot.baseSize
            implicitHeight: dot.baseSize
            radius: height / 2
            color: dot.current ? Colors.primary : (root.showNumbers ? Colors.surfaceContainerHigh : Colors.surfaceFg)
            opacity: dot.current || Hypr.occupied.includes(dot.workspace) ? 1 : Appearance.island.dimmedOpacity

            Behavior on implicitWidth {
                Anim {}
            }

            Behavior on implicitHeight {
                Anim {}
            }

            Behavior on opacity {
                Anim {}
            }

            StyledText {
                id: dotLabel

                anchors.centerIn: parent
                visible: root.showNumbers
                text: `${dot.workspace}`
                color: dot.current ? Colors.primaryFg : Colors.surfaceFg
                font.pixelSize: Appearance.font.size.small
                font.weight: dot.current ? Font.Bold : Font.Medium
            }

            MouseArea {
                // Dots are tiny; extend the hit area into the gaps.
                anchors.fill: parent
                anchors.margins: -Appearance.island.dotGap / 2
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.focus(dot.workspace)
            }
        }
    }
}
