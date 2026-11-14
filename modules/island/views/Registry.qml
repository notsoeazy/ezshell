pragma Singleton

import QtQuick
import Quickshell
import qs.modules.island.views
import qs.modules.island.views.controlpanel
import qs.modules.island.views.launcher

// Every view the island can show, by name. Adding a view means adding it here and nowhere else.
Singleton {
    readonly property var components: ({
            "idle": idle,
            "default": standard,
            "hovered": hovered,
            "controlpanel": controlPanel,
            "launcher": launcher,
            "osd": osd,
            "banner": banner,
            "notifications": notifications,
            "wallpaper": wallpaper,
            "calendar": calendar,
            "session": session
        })
    readonly property list<string> names: Object.keys(components)

    function has(name: string): bool {
        return components[name] !== undefined;
    }

    function component(name: string): Component {
        return components[name] ?? idle;
    }

    Component {
        id: idle

        IdleView {}
    }

    Component {
        id: standard

        DefaultView {}
    }

    Component {
        id: hovered

        HoveredView {}
    }

    Component {
        id: controlPanel

        ControlPanelView {}
    }

    Component {
        id: launcher

        LauncherView {}
    }

    Component {
        id: osd

        OsdView {}
    }

    Component {
        id: banner

        BannerView {}
    }

    Component {
        id: notifications

        NotificationsView {}
    }

    Component {
        id: wallpaper

        WallpaperView {}
    }

    Component {
        id: calendar

        CalendarView {}
    }

    Component {
        id: session

        SessionView {}
    }
}
