pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components
import qs.services
import qs.modules.island

// Lock, log out, restart, shut down. Left and Right move, Return runs. The
// three that end the session ask once more before they do.
View {
    id: root

    readonly property list<var> actions: [
        {
            label: "Lock",
            icon: "lock",
            destructive: false,
            run: () => Session.lock()
        },
        {
            label: "Log Out",
            icon: "logout",
            destructive: true,
            run: () => Session.logout()
        },
        {
            label: "Restart",
            icon: "restart_alt",
            destructive: true,
            run: () => Session.reboot()
        },
        {
            label: "Shut Down",
            icon: "power_settings_new",
            destructive: true,
            run: () => Session.poweroff()
        }
    ]
    // Starts on Lock, the only one that ends nothing.
    property int index
    // The action waiting for a second press, or -1.
    property int confirming: -1

    function select(i: int): void {
        index = Math.max(0, Math.min(actions.length - 1, i));
        confirming = -1;
    }

    function activate(i: int): void {
        index = i;
        const action = actions[i];
        if (action.destructive && confirming !== i) {
            confirming = i;
            return;
        }
        IslandState.close();
        action.run();
    }

    dismissible: true
    wantsKeyboard: true
    margin: Tokens.island.panelPadding

    // Four tiles across the width the other sheets have.
    readonly property real tile: (Tokens.island.sheetContentWidth - Tokens.spacing.md * (actions.length - 1)) / actions.length

    RowLayout {
        spacing: Tokens.spacing.md
        focus: true

        Keys.onLeftPressed: root.select(root.index - 1)
        Keys.onRightPressed: root.select(root.index + 1)
        Keys.onReturnPressed: root.activate(root.index)
        Keys.onEnterPressed: root.activate(root.index)
        Component.onCompleted: forceActiveFocus()

        Repeater {
            model: root.actions

            Surface {
                id: tile

                required property var modelData
                required property int index
                readonly property bool current: index === root.index
                readonly property bool confirming: index === root.confirming

                implicitWidth: root.tile
                implicitHeight: root.tile
                radius: Tokens.radius.lg
                color: confirming ? Theme.color.destructive : Theme.color.fillTertiary
                border.width: current ? Tokens.state.focusRing : 0
                border.color: confirming ? Theme.color.destructive : Theme.accent

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.sm

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        name: tile.modelData.icon
                        size: Tokens.icon.xl
                        color: tile.confirming ? Theme.color.onAccent : Theme.color.label
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: tile.confirming ? "Confirm" : tile.modelData.label
                        emphasized: tile.confirming
                        color: tile.confirming ? Theme.color.onAccent : Theme.color.label
                    }
                }

                Pressable {
                    radius: tile.radius
                    tint: tile.confirming ? Theme.color.onAccent : Theme.color.label
                    onActivated: root.activate(tile.index)
                }
            }
        }
    }
}
