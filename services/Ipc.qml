import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.modules.island
import qs.modules.settings

// One of the two services that reach into modules (Shortcuts is the other):
// the outside doors to them.
// Everything that can be triggered from outside: `qs -p . ipc call <target> <function>`.
Scope {
    IpcHandler {
        function open(view: string): void {
            IslandState.open(view);
        }

        function close(): void {
            IslandState.close();
        }

        function toggle(view: string): void {
            IslandState.toggle(view);
        }

        function pulse(): void {
            IslandState.pulse();
        }

        function current(): string {
            return IslandState.current;
        }

        target: "island"
    }

    IpcHandler {
        function toggle(): void {
            IslandState.toggle("controlpanel");
        }

        // wifi, bluetooth, audio or nightlight
        function page(name: string): void {
            IslandState.openPanel(name);
        }

        target: "controlpanel"
    }

    IpcHandler {
        function volumeUp(): void {
            Audio.changeVolume(0.05);
        }

        function volumeDown(): void {
            Audio.changeVolume(-0.05);
        }

        function toggleMute(): void {
            Audio.toggleMute();
        }

        function toggleMicMute(): void {
            Audio.toggleMicMute();
        }

        function mediaToggle(): void {
            Media.togglePlaying();
        }

        function mediaNext(): void {
            Media.next();
        }

        function mediaPrevious(): void {
            Media.previous();
        }

        target: "audio"
    }

    IpcHandler {
        function up(): void {
            Brightness.change(0.05);
        }

        function down(): void {
            Brightness.change(-0.05);
        }

        target: "brightness"
    }

    IpcHandler {
        // Show a short message: an icon name and the text.
        function toast(icon: string, message: string): void {
            Osd.toast(icon, message);
        }

        // Show a sample message, to look at the display without arguments.
        function test(): void {
            Osd.toast("info", "This is a test message");
        }

        // Show a level, 0 to 1, for something the shell does not manage.
        function level(icon: string, value: real): void {
            Osd.level("", icon, value);
        }

        target: "osd"
    }

    IpcHandler {
        function toggle(): void {
            IslandState.toggle("notifications");
        }

        function clear(): void {
            Notifications.clear();
        }

        function toggleDoNotDisturb(): void {
            ShellState.doNotDisturb = !ShellState.doNotDisturb;
        }

        function count(): int {
            return Notifications.count;
        }

        // Send a real notification through the session bus, for testing. It
        // reaches the shell only if the shell owns the notification server
        // (stop any other shell that does, such as Caelestia, first).
        // `urgency` is "low", "normal" or "critical".
        function send(title: string, body: string, urgency: string): void {
            const level = ["low", "normal", "critical"].includes(urgency) ? urgency : "normal";
            Quickshell.execDetached(["notify-send", "--app-name=ezshell test", `--urgency=${level}`, "--icon=dialog-information", title, body]);
        }

        // Open the list at the newest notification, as a click on its card does.
        function openNewest(): void {
            if (Notifications.count > 0)
                IslandState.openNotification(Notifications.list[0].uid);
        }

        // A sample notification, without arguments.
        function test(): void {
            send("Test notification", "This is a sample message, long enough to see how the text wraps in a banner or the list.", "normal");
        }

        // Send several at once, to see the list and the grouping with many.
        function flood(count: int): void {
            for (let i = 1; i <= Math.min(count, 20); i++)
                send(`Notification ${i}`, `Message number ${i} of ${count}`, i % 7 === 0 ? "critical" : "normal");
        }

        target: "notifications"
    }

    IpcHandler {
        function toggle(): void {
            if (IslandState.requested === "launcher")
                IslandState.close();
            else
                IslandState.openLauncher("");
        }

        // Open with the search already started: ">" for actions, ":" for
        // the clipboard, "." for emoji and symbols, or any text.
        function open(query: string): void {
            IslandState.openLauncher(query);
        }

        target: "launcher"
    }

    IpcHandler {
        // Open the wallpaper selector.
        function selector(): void {
            IslandState.toggle("wallpaper");
        }

        function set(path: string): void {
            Wallpapers.set(path);
        }

        function next(): void {
            Wallpapers.next();
        }

        function current(): string {
            return Wallpapers.current;
        }

        target: "wallpaper"
    }

    IpcHandler {
        function toggle(): void {
            IslandState.toggle("calendar");
        }

        target: "calendar"
    }

    IpcHandler {
        // Open the session view. The rest act at once, with no confirmation.
        function toggle(): void {
            IslandState.toggle("session");
        }

        function lock(): void {
            Session.lock();
        }

        function logout(): void {
            Session.logout();
        }

        function reboot(): void {
            Session.reboot();
        }

        function poweroff(): void {
            Session.poweroff();
        }

        target: "session"
    }

    IpcHandler {
        function toggle(): void {
            SettingsState.toggle();
        }

        // A section name (SettingsState.sections), such as network or sound;
        // anything else opens the section last shown.
        function open(section: string): void {
            SettingsState.open(section);
        }

        target: "settings"
    }

    IpcHandler {
        // Choose a window or an area, then "edit" (open in the editor),
        // "copy", or "save" (save and copy). An empty action means the one
        // in the config.
        function screenshot(action: string): void {
            Capture.screenshot(action);
        }

        // The whole of the focused screen, with the same actions.
        function screen(action: string): void {
            Capture.screenshotScreen(action);
        }

        // Start recording, or stop the one running: "screen", "sound" (the
        // screen with sound) or "region"; empty means the config's mode.
        function record(mode: string): void {
            Capture.record(mode);
        }

        function stop(): void {
            Capture.stop();
        }

        function recording(): bool {
            return Capture.recording;
        }

        // Give up choosing an area.
        function cancel(): void {
            Capture.cancel();
        }

        target: "capture"
    }

    IpcHandler {
        // Show or hide a special workspace by name ("music"); an empty name
        // means the one last shown.
        function toggle(name: string): void {
            Hypr.toggleSpecial(name);
        }

        // The one showing, or nothing.
        function active(): string {
            return Hypr.activeSpecial;
        }

        // Every special workspace that exists, one per line.
        function list(): string {
            return Hypr.specials.join("\n");
        }

        target: "special"
    }

    // Read-only status, mostly for checking the services from a terminal.
    IpcHandler {
        function workspace(): int {
            return Hypr.activeWorkspace;
        }

        function fullscreen(): bool {
            return Hypr.fullscreen;
        }

        function window(): string {
            return `${Hypr.activeAppId} | ${Hypr.activeTitle}`;
        }

        function audio(): string {
            return `volume ${Audio.volume.toFixed(2)} muted ${Audio.muted} mic ${Audio.micVolume.toFixed(2)} micMuted ${Audio.micMuted}`;
        }

        function battery(): string {
            return `available ${Battery.available} level ${Battery.level.toFixed(2)} charging ${Battery.charging} pluggedIn ${Battery.pluggedIn}`;
        }

        function network(): string {
            return `wifiEnabled ${Network.wifiEnabled} ssid "${Network.ssid}" strength ${Network.strength.toFixed(2)} wired ${Network.wiredConnected}`;
        }

        function brightness(): string {
            return `available ${Brightness.available} device ${Brightness.device} value ${Brightness.value.toFixed(2)}`;
        }

        function bluetooth(): string {
            return `available ${Bluetooth.available} enabled ${Bluetooth.enabled} devices ${Bluetooth.devices.map(d => d.name + (d.connected ? "*" : "")).join(", ")}`;
        }

        function sound(): string {
            return `sinks ${Audio.sinks.map(n => Audio.label(n)).join(" | ")} || sources ${Audio.sources.map(n => Audio.label(n)).join(" | ")}`;
        }

        function media(): string {
            return `available ${Media.available} playing ${Media.playing} "${Media.title}" by "${Media.artist}"`;
        }

        // The windows the capture chooser would offer on the first screen.
        function windows(): string {
            return Hypr.windowsOn(Quickshell.screens[0]).map(w => `${w.x},${w.y} ${w.width}x${w.height}`).join(" | ");
        }

        target: "status"
    }
}
