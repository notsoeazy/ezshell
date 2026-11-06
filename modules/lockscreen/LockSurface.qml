import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.themes

// One screen of the lockscreen: wallpaper under a scrim, clock, date, password pill.
StyledRect {
    id: root

    required property ShellScreen screen
    property string error: ""
    property bool busy: false
    property int failures: 0
    readonly property color outline: Qt.alpha(Colors.outlineVariant, Appearance.island.outlineOpacity)

    signal submitted(string password)

    color: Colors.surface
    onFailuresChanged: input.text = ""
    Component.onCompleted: input.forceActiveFocus()

    Image {
        anchors.fill: parent
        visible: Config.wallpaper.path !== ""
        source: Config.wallpaper.path !== "" ? `file://${Config.wallpaper.path}` : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.screen?.width ?? 0
        sourceSize.height: root.screen?.height ?? 0
    }

    StyledRect {
        anchors.fill: parent
        color: Qt.alpha(Colors.island, Appearance.lock.scrimOpacity)
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacing.large

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(Time.date, Time.timeFormat)
            font.pixelSize: Appearance.font.size.display
            font.weight: Font.DemiBold
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(Time.date, "dddd, d MMMM")
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.large
        }

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.spacing.large
            implicitWidth: Appearance.lock.inputWidth
            implicitHeight: Appearance.lock.inputHeight
            radius: height / 2
            color: Colors.island
            border.width: Appearance.island.outlineWidth
            border.color: root.error !== "" ? Colors.error : root.outline

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacing.large
                anchors.rightMargin: Appearance.spacing.large
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "lock"
                    color: Colors.surfaceVariantFg
                }

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    enabled: !root.busy
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: Colors.surfaceFg
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.size.title
                    focus: true
                    onAccepted: root.submitted(input.text)
                }

                MaterialIcon {
                    text: root.busy ? "hourglass_empty" : "arrow_forward"
                    color: Colors.surfaceVariantFg
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            opacity: root.error !== "" ? 1 : 0
            text: root.error
            color: Colors.error
            font.weight: Font.Medium

            Behavior on opacity {
                Anim {}
            }
        }
    }
}
