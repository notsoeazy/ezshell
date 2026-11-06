pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.themes

// Editor for Config.workspaces.special. Every change builds a new list and assigns it whole:
// edits inside a list<var> may not trigger a save (DESIGN.md).
ColumnLayout {
    id: root

    readonly property var special: Config.workspaces.special

    function copy(): var {
        return root.special.map(w => Object.assign({}, w));
    }

    // Names are the IPC keys (`hypr toggleSpecial <name>`), so they must be non-empty and unique.
    function update(index: int, key: string, value: string): bool {
        const taken = key === "name" && root.special.some((w, i) => i !== index && w.name === value);
        if (taken || (key === "name" && value === ""))
            return false;
        const list = root.copy();
        list[index][key] = value;
        Config.workspaces.special = list;
        return true;
    }

    function remove(index: int): void {
        Config.workspaces.special = root.copy().filter((w, i) => i !== index);
    }

    function add(): void {
        let n = root.special.length + 1;
        while (root.special.some(w => w.name === `special${n}`))
            n++;
        Config.workspaces.special = root.copy().concat([
            {
                name: `special${n}`,
                icon: "layers",
                exec: "",
                kind: "workspace"
            }
        ]);
    }

    spacing: Appearance.settings.padding

    Section {
        title: "Special workspaces"
        description: "Toggle one with `qs ipc call hypr toggleSpecial <name>`. Exec starts the first time it opens."

        Repeater {
            model: root.special

            Entry {}
        }

        StyledButton {
            text: "Add"
            icon: "add"
            onClicked: root.add()
        }
    }

    component Entry: ColumnLayout {
        id: entry

        required property var modelData
        required property int index
        readonly property string kind: entry.modelData.kind ?? "workspace"

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        RowLayout {
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: entry.modelData.icon
            }

            StyledTextField {
                id: name

                implicitWidth: Appearance.control.narrowFieldWidth
                text: entry.modelData.name
                placeholder: "name"
                onEditingFinished: {
                    if (!root.update(entry.index, "name", name.text.trim()))
                        name.text = entry.modelData.name;
                }
            }

            StyledTextField {
                implicitWidth: Appearance.control.narrowFieldWidth
                text: entry.modelData.icon
                placeholder: "icon"
                onEditingFinished: root.update(entry.index, "icon", text.trim())
            }

            Item {
                Layout.fillWidth: true
            }

            StyledButton {
                icon: "delete"
                onClicked: root.remove(entry.index)
            }
        }

        RowLayout {
            spacing: Appearance.spacing.normal

            StyledTextField {
                Layout.fillWidth: true
                text: entry.modelData.exec ?? ""
                placeholder: "command to run the first time (optional)"
                onEditingFinished: root.update(entry.index, "exec", text.trim())
            }

            StyledButton {
                text: "App"
                checked: entry.kind === "app"
                onClicked: root.update(entry.index, "kind", "app")
            }

            StyledButton {
                text: "Workspace"
                checked: entry.kind === "workspace"
                onClicked: root.update(entry.index, "kind", "workspace")
            }
        }
    }
}
