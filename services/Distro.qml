pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The Linux distribution, from /etc/os-release.
Singleton {
    id: root

    readonly property string name: field("NAME")
    readonly property string id: field("ID")
    // The distribution's logo as an icon theme name (`LOGO=`), possibly empty.
    readonly property string logo: field("LOGO")

    readonly property var fields: parse(file.text())

    function field(key: string): string {
        return fields[key] ?? "";
    }

    function parse(text: string): var {
        const result = {};
        for (const line of text.split("\n")) {
            const match = line.match(/^([A-Z_]+)=(.*)$/);
            if (match)
                result[match[1]] = match[2].replace(/^["']|["']$/g, "");
        }
        return result;
    }

    FileView {
        id: file

        path: "/etc/os-release"
        blockLoading: true
    }
}
