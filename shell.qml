import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.lockscreen
import qs.modules.settings
import qs.modules.wallpaper
import qs.services

ShellRoot {
    // Singletons load lazily. These must be live at startup: NightLight applies the saved state,
    // Notifs must own the notification bus name before the first notification arrives, Players backs
    // media keys, Idle runs the idle timers, Apps indexes desktop entries before the launcher opens and
    // Wallpapers, Clipboard, Emoji, Capture and Color own their IPC, and Polkit registers the authentication agent.
    Component.onCompleted: {
        Notifs;
        Players;
        Idle;
        Session;
        Weather;
        SysInfo;
        Camera;
        Theme;
        Wallpapers;
        Clipboard;
        Emoji;
        Polkit;
        Capture;
        Color;
        Apps;
        Audio;
        Brightness;
        NightLight;
    }

    Wallpaper {}
    Island {}
    Lockscreen {}
    Settings {}
}
