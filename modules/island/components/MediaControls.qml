pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components
import qs.components.controls
import qs.services

// The current track, in the manner of Apple's Now Playing: artwork, title,
// the artist and player, a scrubber with the times either side of it, and
// previous, play/pause and next as plain filled glyphs. Meant to sit in a
// `Card`.
RowLayout {
    spacing: Tokens.spacing.md

    // Ask the player for its position while this is on screen.
    Binding {
        target: Media
        property: "watching"
        value: true
    }

    ClippingRectangle {
        implicitWidth: Tokens.island.mediaArt
        implicitHeight: Tokens.island.mediaArt
        radius: Tokens.radius.md
        color: Theme.color.fill

        Icon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            name: "music_note"
            level: Icon.Secondary
        }

        Image {
            id: art

            anchors.fill: parent
            source: Media.artUrl
            sourceSize.width: Tokens.island.mediaArt * 2
            sourceSize.height: Tokens.island.mediaArt * 2
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Label {
            Layout.fillWidth: true
            text: Media.title.length > 0 ? Media.title : "Not playing"
            emphasized: true
        }

        Label {
            Layout.fillWidth: true
            visible: text.length > 0
            text: [Media.artist, Media.source].filter(part => part.length > 0).join(" · ")
            fontSize: Tokens.fontSize.sm
            level: Label.Secondary
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.sm

            // The times and the progress only when the player's position can be
            // believed (browser video often cannot); otherwise just the empty
            // bar. It can be dragged only where the player can seek.
            Label {
                visible: Media.hasProgress
                text: Time.duration(scrubber.shownValue)
                fontSize: Tokens.fontSize.xs
                level: Label.Secondary
                tabular: true
            }

            Scrubber {
                id: scrubber

                Layout.fillWidth: true
                from: 0
                to: Math.max(1, Media.length)
                value: Media.hasProgress ? Media.position : 0
                interactive: Media.canSeek
                onMoved: value => Media.seek(value)
            }

            Label {
                visible: Media.hasProgress
                text: Time.duration(Media.length)
                fontSize: Tokens.fontSize.xs
                level: Label.Secondary
                tabular: true
            }
        }
    }

    RowLayout {
        spacing: 0

        IconButton {
            icon: "skip_previous"
            iconFilled: true
            style: Button.Plain
            onActivated: Media.previous()
        }

        IconButton {
            icon: Media.playing ? "pause" : "play_arrow"
            iconFilled: true
            size: Tokens.size.xxl
            style: Button.Plain
            onActivated: Media.togglePlaying()
        }

        IconButton {
            icon: "skip_next"
            iconFilled: true
            style: Button.Plain
            onActivated: Media.next()
        }
    }
}
