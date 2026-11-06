pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules.island.dashboard
import qs.modules.island.sections
import qs.services
import qs.state
import qs.themes

// Expanded island: ExpandedHeader over the open section, or over the notification list sub-page.
// The surface morphs to this item's implicitHeight; sections never write sizes into state.
ColumnLayout {
    id: root

    required property string screenName
    readonly property string section: Visibility.panel
    // A dashboard-level sub-page (the notification list) replaces the tab under a back-chevron header.
    readonly property bool onNotifications: Visibility.stack[Visibility.stack.length - 1] === "notifications"
    readonly property string subpage: root.onNotifications ? "notifications" : ""
    readonly property string page: root.subpage !== "" ? root.subpage : root.section
    // The page on screen: follows `page` through a fade-out / swap / fade-in (ISLAND.md "Expanded layout
    // and navigation"), so a section change cross-fades while the surface morphs to the new height.
    property string shownPage: root.page
    readonly property bool onTab: Visibility.tabs.includes(root.section) && root.subpage === ""
    readonly property var pages: ({
            "overview": overviewPage,
            "media": mediaPage,
            "system": systemPage,
            "calendar": calendarPage,
            "wifi": wifiPage,
            "bluetooth": bluetoothPage,
            "audio": audioPage,
            "power": powerPage,
            "wallpapers": wallpapersPage,
            "notifications": notificationsPage
        })

    spacing: Appearance.island.expanded.gap
    focus: true
    Keys.onEscapePressed: Visibility.back()
    // Restarting mid-swap fades out from the current opacity and lands on the latest page.
    onPageChanged: pageSwap.restart()

    SequentialAnimation {
        id: pageSwap

        Anim {
            target: pageLoader
            property: "opacity"
            to: 0
            duration: Appearance.anim.scaled(Appearance.anim.islandFadeOut)
        }

        ScriptAction {
            script: root.shownPage = root.page
        }

        Anim {
            target: pageLoader
            property: "opacity"
            to: 1
            duration: Appearance.anim.scaled(Appearance.anim.islandFadeIn)
        }
    }

    // Services sample only while something shows their data; these bindings go away on collapse,
    // which switches the services back off.
    Binding {
        target: SysInfo
        property: "active"
        value: root.onTab && (root.section === "overview" || root.section === "system")
    }

    Binding {
        target: Weather
        property: "active"
        value: root.onTab && (root.section === "overview" || root.section === "system")
    }

    Binding {
        target: Players
        property: "tracking"
        value: root.onTab && (root.section === "overview" || root.section === "media")
    }

    ExpandedHeader {
        Layout.fillWidth: true
        screenName: root.screenName
        section: root.section
        page: root.page
        onTab: root.onTab
    }

    Loader {
        id: pageLoader

        Layout.fillWidth: true
        sourceComponent: root.pages[root.shownPage] ?? null
    }

    Component {
        id: notificationsPage

        NotificationList {}
    }

    Component {
        id: overviewPage

        OverviewTab {
            screenName: root.screenName
        }
    }

    Component {
        id: mediaPage

        MediaTab {}
    }

    Component {
        id: systemPage

        SystemTab {}
    }

    Component {
        id: calendarPage

        CalendarTab {}
    }

    Component {
        id: wifiPage

        WifiSection {}
    }

    Component {
        id: bluetoothPage

        BluetoothSection {}
    }

    Component {
        id: audioPage

        AudioSection {}
    }

    Component {
        id: powerPage

        PowerSection {}
    }

    Component {
        id: wallpapersPage

        WallpapersSection {}
    }
}
