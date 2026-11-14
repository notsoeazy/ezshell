pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.island

// One notification. Collapsed it is a picture, the title with how long ago, and
// one line of the body, cut off with an ellipsis, with a chevron. Open it with
// the chevron (or by dragging down; up closes it) and the body wraps in full,
// with the app's own buttons and some of ours: open the app, copy the text,
// silence the app, dismiss. Drag it sideways to dismiss it.
//
//   framed         a fill behind it (off on the banner, which has the island, and
//                  in a group, which has its own)
//   padding        space between its edge and its content; the hover highlight
//                  fills the whole padded area (default: a card's, none unframed)
//   radius         corner radius of the card and its highlight (0 in a group)
//   pictureSize    the picture's size (default Tokens.control.xl)
//   clickable      the card can be clicked (`opened`), apart from its chevron
//   toggleOnClick  a click on the card opens or closes it, like the chevron
//   showApp        name the app next to the title when it is open (off where a
//                  header already does)
//   verticalExpand dragging down or up opens or closes it (off where the
//                  list scrolls, since the drag would be the scroll)
SwipeToDismiss {
    id: root

    // May become null while the item is still fading out.
    required property NotifData notification
    property bool framed: true
    property real padding: framed ? Tokens.spacing.md : 0
    property real radius: Tokens.radius.lg
    property real pictureSize: Tokens.control.xl
    property bool clickable
    property bool toggleOnClick
    property bool showApp: true
    property bool expanded: Config.notifications.openExpanded
    property bool verticalExpand
    // Whether it is the one a click led here (the list outlines it).
    readonly property string pictureSource: notification ? notification.picture : ""
    readonly property string bodyText: notification ? notification.body : ""
    readonly property bool highlighted: notification !== null && IslandState.focusedNotification === notification.uid

    signal opened
    // Sent when it has been highlighted, so a list can scroll to it.
    signal revealed(item: Item)

    function reveal(): void {
        if (highlighted)
            revealed(root);
    }

    threshold: Config.notifications.dismissThreshold
    onDismissed: Notifications.dismiss(notification)
    onHighlightedChanged: Qt.callLater(reveal)
    Component.onCompleted: Qt.callLater(reveal)

    Card {
        id: frame

        anchors.left: parent.left
        anchors.right: parent.right
        interactive: root.clickable || root.toggleOnClick
        padding: root.padding
        radius: root.radius
        color: root.framed ? Theme.color.fillTertiary : Qt.alpha(Theme.color.fillTertiary, 0)
        onActivated: {
            if (root.clickable)
                root.opened();
            else
                root.expanded = !root.expanded;
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Tokens.spacing.sm

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.md

                ClippingRectangle {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: root.pictureSize
                    implicitHeight: root.pictureSize
                    radius: Tokens.radius.sm
                    color: picture.visible ? Qt.alpha(Theme.color.fill, 0) : Theme.color.fill

                    Icon {
                        anchors.centerIn: parent
                        visible: !picture.visible
                        name: "notifications"
                        level: Icon.Secondary
                    }

                    Image {
                        id: picture

                        anchors.fill: parent
                        visible: root.pictureSource.length > 0 && status === Image.Ready
                        source: root.pictureSource
                        sourceSize.width: Tokens.control.xl * 2
                        sourceSize.height: Tokens.control.xl * 2
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        id: titleRow

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.xs

                        Label {
                            Layout.maximumWidth: titleRow.width - age.implicitWidth - titleRow.spacing
                            text: root.notification?.summary ?? ""
                            emphasized: true
                        }

                        Label {
                            id: age

                            text: root.expanded && root.showApp ? `· ${root.notification?.appName ?? ""} · ${Notifications.age(root.notification)}` : `· ${Notifications.age(root.notification)}`
                            fontSize: Tokens.fontSize.xs
                            level: Label.Secondary
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: root.bodyText
                        level: Label.Secondary
                        wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
                        maximumLineCount: root.expanded ? Config.notifications.bodyLines : 1
                    }
                }

                IconButton {
                    Layout.alignment: Qt.AlignTop
                    icon: "expand_more"
                    style: Button.Plain
                    neutral: true
                    size: Tokens.size.sm
                    rotation: root.expanded ? 180 : 0
                    onActivated: root.expanded = !root.expanded

                    Behavior on rotation {
                        Anim {
                            style: Tokens.motion.spatialFast
                        }
                    }
                }
            }

            // Opened: the app, its buttons, and ours.
            Reveal {
                Layout.fillWidth: true
                shown: root.expanded
                collapse: Reveal.Vertical

                ColumnLayout {
                    spacing: Tokens.spacing.sm

                    Flow {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.xs

                        Repeater {
                            model: root.notification?.live ? root.notification.actions : []

                            Button {
                                required property var modelData

                                text: modelData.text
                                size: Tokens.size.md
                                style: Button.Tinted
                                onActivated: Notifications.invoke(root.notification, modelData.identifier)
                            }
                        }

                        Button {
                            visible: Notifications.entryFor(root.notification) !== null
                            text: "Open"
                            icon: "open_in_new"
                            size: Tokens.size.md
                            onActivated: Notifications.openApp(root.notification)
                        }

                        Button {
                            visible: root.bodyText.length > 0
                            text: "Copy"
                            icon: "content_copy"
                            size: Tokens.size.md
                            onActivated: Clipboard.copyText(`${root.notification.summary}\n${root.notification.body}`)
                        }

                        Button {
                            readonly property bool silenced: Notifications.isSilenced(root.notification?.appName ?? "")

                            text: silenced ? "Unsilence" : "Silence"
                            icon: silenced ? "notifications_active" : "notifications_off"
                            size: Tokens.size.md
                            onActivated: Notifications.toggleSilenced(root.notification.appName)
                        }

                        Button {
                            text: "Dismiss"
                            icon: "close"
                            size: Tokens.size.md
                            role: Button.Destructive
                            onActivated: Notifications.dismiss(root.notification)
                        }
                    }
                }
            }
        }
    }

    // Drag down to open, up to close, once per drag. A sibling of the card, not
    // inside it: inside, it would sit over the card's click area and take its clicks.
    DragHandler {
        property bool done

        enabled: root.verticalExpand
        target: null
        xAxis.enabled: false
        onActiveChanged: done = false
        onTranslationChanged: {
            if (!active || done || Math.abs(translation.y) < Config.notifications.expandThreshold)
                return;

            root.expanded = translation.y > 0;
            done = true;
        }
    }

    // The outline of the one a click led here, for a moment.
    Rectangle {
        anchors.fill: frame
        radius: frame.radius
        color: Qt.alpha(Theme.accent, 0)
        border.width: Tokens.state.focusRing
        border.color: Theme.accent
        opacity: root.highlighted ? 1 : 0

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effects
            }
        }
    }
}
