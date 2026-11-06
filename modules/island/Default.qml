import QtQuick
import QtQuick.Layouts
import qs.components
import qs.themes

// Balance rule (docs/ISLAND.md): equal-width sides keep the clock centered on the island and the screen.
RowLayout {
    id: root

    required property string screenName
    property real animatedSideWidth: root.sideWidth
    readonly property real sideWidth: Math.max(leading.implicitWidth, trailing.implicitWidth)
    // Room for the two equal sides inside Appearance.island.maxWidth.
    readonly property real chrome: 2 * Appearance.island.padding + clock.implicitWidth + 2 * root.spacing
    readonly property real sideBudget: (Appearance.island.maxWidth - root.chrome) / 2
    // How many labels/counts to drop, lowest priority first (docs/ISLAND.md): 1 the unread count,
    // 2 the special chip's name, 3 the battery percentage. Music, mic/camera and recording are icons already.
    readonly property int compactLevel: [0, 1, 2, 3].find(level => root.sideAt(level) <= root.sideBudget) ?? 3

    function sideAt(level: int): real {
        const left = leading.naturalWidth - (level >= 2 ? leading.specialSaving : 0);
        const saved = (level >= 1 ? trailing.badgeSaving : 0) + (level >= 3 ? trailing.batterySaving : 0);
        const right = trailing.naturalWidth - saved;
        return Math.max(left, right);
    }

    spacing: Appearance.spacing.normal

    Behavior on animatedSideWidth {
        Anim {}
    }

    Item {
        Layout.preferredWidth: root.animatedSideWidth
        Layout.fillHeight: true

        Leading {
            id: leading

            screenName: root.screenName
            compactSpecial: root.compactLevel >= 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Clock {
        id: clock
    }

    Item {
        Layout.preferredWidth: root.animatedSideWidth
        Layout.fillHeight: true

        Trailing {
            id: trailing

            screenName: root.screenName
            compactBadge: root.compactLevel >= 1
            compactBattery: root.compactLevel >= 3
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
