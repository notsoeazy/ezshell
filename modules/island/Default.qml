import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.themes

// Balance rule (docs/ISLAND.md): equal-width sides keep the clock centered when balancedWings is true.
// Leading hugs the left edge and Trailing the right, so when the pill widens (peek) they move with it.
RowLayout {
    id: root

    required property string screenName
    property real animatedLeadingWidth: root.leadingTargetWidth
    property real animatedTrailingWidth: root.trailingTargetWidth
    readonly property bool balanced: Config.island.balancedWings
    readonly property real sideWidth: Math.max(leading.implicitWidth, trailing.implicitWidth)
    readonly property real leadingTargetWidth: root.balanced ? root.sideWidth : leading.implicitWidth
    readonly property real trailingTargetWidth: root.balanced ? root.sideWidth : trailing.implicitWidth
    // Room for the two wings inside Appearance.island.maxWidth.
    readonly property real chrome: 2 * Appearance.island.padding + clock.implicitWidth + 2 * root.spacing
    readonly property real wingBudget: Appearance.island.maxWidth - root.chrome
    // How many labels/counts to drop, lowest priority first (docs/ISLAND.md): 1 the unread count,
    // 2 the special chip's name, 3 the battery percentage. Music, mic/camera and recording are icons already.
    readonly property int compactLevel: [0, 1, 2, 3].find(level => root.wingsWidthAt(level) <= root.wingBudget) ?? 3

    function wingsWidthAt(level: int): real {
        const left = leading.naturalWidth - (level >= 2 ? leading.specialSaving : 0);
        const saved = (level >= 1 ? trailing.badgeSaving : 0) + (level >= 3 ? trailing.batterySaving : 0);
        const right = trailing.naturalWidth - saved;
        return root.balanced ? 2 * Math.max(left, right) : left + right;
    }

    spacing: Appearance.island.sectionGap

    Behavior on animatedLeadingWidth {
        Anim {}
    }

    Behavior on animatedTrailingWidth {
        Anim {}
    }

    // Both sides share any width beyond the content equally (the peek), so the clock stays put.
    Item {
        Layout.preferredWidth: root.animatedLeadingWidth
        Layout.fillWidth: true
        Layout.horizontalStretchFactor: 1
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
        Layout.preferredWidth: root.animatedTrailingWidth
        Layout.fillWidth: true
        Layout.horizontalStretchFactor: 1
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
