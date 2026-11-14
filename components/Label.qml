import QtQuick
import qs.config
import qs.theme

// All text. Models HIG labels: a size and weight from the font tokens plus a
// vibrancy level, instead of a raw size and colour.
Text {
    id: root

    enum Level {
        Primary,
        Secondary,
        Tertiary,
        Quaternary
    }

    property real fontSize: Tokens.fontSize.md
    // Semibold when `emphasized`, else regular; set it to pick another.
    property int weight: emphasized ? Tokens.fontWeight.semibold : Tokens.fontWeight.regular
    property bool emphasized
    property bool mono
    // Fixed-width digits, for clocks and other changing numbers.
    property bool tabular
    property int level: Label.Primary
    readonly property color levelColor: [Theme.color.label, Theme.color.labelSecondary, Theme.color.labelTertiary, Theme.color.labelQuaternary][level]

    color: levelColor
    font.family: mono ? Tokens.font.mono : Tokens.font.family
    font.pixelSize: fontSize
    // Geist is a variable font, so weight is set on its axis. Setting
    // font.weight as well makes Qt add synthetic bold on top, and setting only
    // font.weight snaps in-between weights (medium, semibold) to regular.
    font.variableAxes: ({
            "wght": weight
        })
    font.features: tabular ? ({
            "tnum": 1
        }) : ({})
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    elide: Text.ElideRight

    Behavior on color {
        ColorAnim {}
    }
}
