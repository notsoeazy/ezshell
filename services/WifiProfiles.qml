import QtQuick
import Quickshell
import Quickshell.Io

// Saved NetworkManager profiles and hidden networks, through nmcli. Quickshell only lists in-range
// networks and can't join one that never shows up in a scan. Owned by the Wifi service, not a singleton.
Scope {
    id: root

    // Saved Wi‑Fi profiles as { name, uuid }, in range or not. refresh() re-reads them (on demand, not polled).
    readonly property var saved: internal.saved

    signal hiddenFailed

    function refresh(): void {
        savedReader.exec(["nmcli", "--terse", "--fields", "UUID,TYPE,NAME", "connection", "show"]);
    }

    // Deletes one profile by UUID, so duplicate profiles for one SSID can be removed separately.
    function forget(uuid: string): void {
        profileAction.exec(["nmcli", "connection", "delete", "uuid", uuid]);
    }

    // The password goes through stdin (--ask), not argv, so it never shows up in the process list.
    function connectHidden(ssid: string, password: string): void {
        internal.hiddenPassword = password;
        hiddenConnect.exec(["nmcli", "--ask", "device", "wifi", "connect", ssid, "hidden", "yes"]);
    }

    // nmcli --terse escapes ":" inside fields as "\:"; NAME is last so only the first two separators split.
    function parse(text: string): var {
        const rows = text.trim().split("\n").filter(line => line !== "");
        const parseRow = line => {
            const [uuid, type, ...rest] = line.split(":");
            return {
                uuid: uuid,
                type: type,
                name: rest.join(":").replace(/\\:/g, ":")
            };
        };
        return rows.map(parseRow).filter(p => p.type === "802-11-wireless").map(p => ({
                    name: p.name,
                    uuid: p.uuid
                }));
    }

    QtObject {
        id: internal

        property var saved: []
        property string hiddenPassword: ""
    }

    Process {
        id: savedReader

        stdout: StdioCollector {
            onStreamFinished: internal.saved = root.parse(text)
        }
    }

    Process {
        id: profileAction

        onExited: code => {
            if (code !== 0)
                console.warn(`[wifi] nmcli connection delete exited with ${code}`);
            root.refresh();
        }
    }

    Process {
        id: hiddenConnect

        stdinEnabled: true
        onStarted: {
            hiddenConnect.write(internal.hiddenPassword + "\n");
            internal.hiddenPassword = "";
        }
        onExited: code => {
            if (code !== 0)
                root.hiddenFailed();
            root.refresh();
        }
    }
}
