import QtQuick
import Quickshell.Services.Notifications

// One notification, as the shell keeps it: a copy of what the app sent, so it
// can be saved and shown again after a restart. `source` is the live object
// from the notification server while the app that sent it is still connected;
// it is null for one restored from the file, which can be read and dismissed
// but not acted on.
QtObject {
    required property string uid
    property string appName
    property string desktopEntry
    property string summary
    property string body
    // A picture to show: the notification's own image, else its app's icon.
    property string picture
    property int urgency: NotificationUrgency.Normal
    // When it arrived, in ms since the epoch.
    property real time
    // The app's buttons: [{ identifier, text }].
    property var actions: []
    property var source: null

    readonly property bool live: source !== null
}
