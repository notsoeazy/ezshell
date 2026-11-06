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
    readonly property int active: Hypr.activeWorkspace(root.screenName)

    spacing: Appearance.island.dotGap

    Repeater {
        model: Config.workspaces.shown

        StyledRect {
            id: dot

            required property int index
            readonly property int workspace: index + 1
            readonly property bool current: root.active === workspace

            implicitWidth: dot.current ? Appearance.island.activeDot : Appearance.island.dot
            implicitHeight: Appearance.island.dot
            radius: height / 2
            color: dot.current ? Colors.primary : Colors.surfaceFg
            opacity: dot.current || Hypr.occupied.includes(dot.workspace) ? 1 : Appearance.island.dimmedOpacity

            Behavior on implicitWidth {
                Anim {}
            }

            Behavior on opacity {
                Anim {}
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
