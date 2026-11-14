pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components
import qs.components.containers
import qs.services
import qs.modules.island

// The wallpaper selector: a strip of thumbnails. Left and Right move, and the
// selected wallpaper is previewed on the real background. Return sets it;
// closing any other way puts the old one back.
View {
    id: root

    property int index: Math.max(0, Wallpapers.list.indexOf(Wallpapers.current))
    property bool committed
    // Whether the strip has been scrolled to the current wallpaper.
    property bool placed

    function select(i: int): void {
        if (Wallpapers.list.length === 0)
            return;

        index = Math.max(0, Math.min(Wallpapers.list.length - 1, i));
        Wallpapers.preview = Wallpapers.list[index];
    }

    // Open on the wallpaper that is set, in the middle of the strip. A list
    // view does not scroll to its starting item by itself, so without this
    // the strip opens at the first picture and the selection is off screen.
    function place(): void {
        if (strip.count === 0)
            return;

        strip.positionViewAtIndex(index, ListView.Center);
        placed = true;
    }

    function commit(): void {
        if (Wallpapers.list.length === 0)
            return;

        Wallpapers.set(Wallpapers.list[index]);
        committed = true;
        IslandState.close();
    }

    dismissible: true
    wantsKeyboard: true
    margin: Tokens.island.panelPadding

    Component.onDestruction: {
        if (!committed)
            Wallpapers.preview = "";
    }

    ColumnLayout {
        spacing: Tokens.spacing.md

        Label {
            visible: Wallpapers.list.length === 0
            text: `No pictures found in ${Config.wallpaper.directory}.`
            level: Label.Secondary
        }

        ListView {
            id: strip

            // Room around the thumbnails for the chosen one, which is drawn larger.
            readonly property real thumbHeight: Tokens.island.wallpaperThumb * 9 / 16
            readonly property real grow: Tokens.state.chosenScale - 1

            Layout.preferredWidth: Tokens.island.wallpaperThumb * 5 + Tokens.spacing.xxxl * 4
            Layout.preferredHeight: thumbHeight * Tokens.state.chosenScale + Tokens.spacing.xs * 2
            visible: Wallpapers.list.length > 0
            orientation: ListView.Horizontal
            // The chosen thumbnail grows by 24 on each side; this leaves a gap
            // of 8 between it and its neighbours.
            spacing: Tokens.spacing.xxxl
            clip: true
            focus: true
            boundsBehavior: Flickable.StopAtBounds
            model: Wallpapers.list
            currentIndex: root.index
            // No travel until the strip has been put on the current
            // wallpaper; after that, moves glide.
            highlightMoveDuration: root.placed ? Tokens.motion.spatialFast.duration : 0
            // Keep the selection in the middle of the strip.
            preferredHighlightBegin: (width - Tokens.island.wallpaperThumb) / 2
            preferredHighlightEnd: (width + Tokens.island.wallpaperThumb) / 2
            highlightRangeMode: ListView.ApplyRange

            Keys.onLeftPressed: root.select(root.index - 1)
            Keys.onRightPressed: root.select(root.index + 1)
            Keys.onReturnPressed: root.commit()
            Keys.onEnterPressed: root.commit()
            Component.onCompleted: {
                forceActiveFocus();
                root.place();
            }
            // The list of pictures can arrive after the view opens.
            onCountChanged: root.place()

            delegate: Item {
                id: cell

                required property string modelData
                required property int index
                readonly property bool current: index === root.index
                // How much larger than the others the thumbnail is drawn. It is
                // the thumbnail's real size that changes, not a transform on it,
                // so it is drawn sharp at every size along the way.
                property real factor: current ? Tokens.state.chosenScale : 1

                width: Tokens.island.wallpaperThumb
                height: ListView.view.height
                // The chosen one on top, where it grows over its neighbours' gap.
                z: current ? 1 : 0

                Behavior on factor {
                    Anim {
                        style: Tokens.motion.spatialFast
                    }
                }

                ClippingRectangle {
                    id: thumb

                    anchors.centerIn: parent
                    width: parent.width * cell.factor
                    height: strip.thumbHeight * cell.factor
                    radius: Tokens.radius.md
                    color: Theme.color.fill

                    Image {
                        anchors.fill: parent
                        source: Wallpapers.thumbnail(cell.modelData)
                        // The thumbnails are made twice as big as they are drawn
                        // unchosen, so that the chosen one is not blown up.
                        sourceSize.width: Tokens.island.wallpaperThumb * 2
                        sourceSize.height: Tokens.island.wallpaperThumb * 2
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // The ring over the picture's edge, not around it: no gap
                    // between them.
                    Rectangle {
                        anchors.fill: parent
                        radius: thumb.radius
                        color: Qt.alpha(Theme.accent, 0)
                        border.width: Tokens.state.focusRing
                        border.color: Theme.accent
                        opacity: cell.current ? 1 : 0

                        Behavior on opacity {
                            Anim {
                                style: Tokens.motion.effectsFast
                            }
                        }
                    }

                    Pressable {
                        onActivated: root.select(cell.index)
                    }
                }
            }
        }

        // The file's name on the left and where it is in the list on the right.
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.spacing.md
            Layout.rightMargin: Tokens.spacing.md
            visible: Wallpapers.list.length > 0

            Label {
                Layout.fillWidth: true
                text: Wallpapers.name(Wallpapers.list[root.index] ?? "")
                level: Label.Secondary
            }

            Label {
                text: `${root.index + 1} of ${Wallpapers.list.length}`
                level: Label.Secondary
                tabular: true
            }
        }

        // The keys, as in the launcher: what they do on the left, Escape (which
        // puts the old wallpaper back) on the far right.
        KeyHints {
            Layout.fillWidth: true
            closeLabel: "cancel"
            hints: [
                {
                    key: "←→",
                    text: "browse"
                },
                {
                    key: "↵",
                    text: "enter"
                }
            ]
        }
    }
}
