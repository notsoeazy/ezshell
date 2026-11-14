pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.theme

// All glyphs: a Material Symbol (Rounded) by name. The font is variable, so
// fill and weight are continuous and animate; a change of name crossfades.
Item {
    id: root

    enum Level {
        Primary,
        Secondary,
        Tertiary
    }

    required property string name
    // The selected / on state. Animates the outline filling in.
    property bool filled
    // 0 = outlined, 1 = filled. Follows `filled`; set it directly for an
    // in-between value.
    property real fill: filled ? 1 : 0
    // Stroke weight, as a font weight (Font.Light .. Font.Bold). Match the
    // weight of the text the icon sits beside.
    property int weight: Font.Normal
    // Fine emphasis without changing size; negative thins light-on-dark icons.
    property real grade
    property real size: Tokens.icon.md
    property int level: Icon.Primary
    property color color: [Theme.color.label, Theme.color.labelSecondary, Theme.color.labelTertiary][level]

    readonly property string symbol: name
    // Each distinct axis value is a separate font instance, so fill moves in
    // tenths rather than every frame's exact value.
    readonly property real fillStep: Math.round(fill * 10) / 10
    // The font redraws detail for the size it is shown at, within its range.
    readonly property real opticalSize: Math.max(Tokens.font.iconOpticalMin, Math.min(Tokens.font.iconOpticalMax, size))

    // What is drawn: the current symbol, and the one it is replacing.
    property string shownSymbol
    property string previousSymbol
    // 0 = previous symbol fully visible, 1 = current symbol fully visible.
    property real progress: 1
    property bool ready

    function swap(): void {
        if (!ready || symbol === shownSymbol)
            return;

        previousSymbol = shownSymbol;
        shownSymbol = symbol;
        swapAnim.restart();
    }

    implicitWidth: size
    implicitHeight: size

    onSymbolChanged: swap()

    Component.onCompleted: {
        shownSymbol = symbol;
        ready = true;
    }

    Behavior on fill {
        Anim {}
    }

    Behavior on color {
        ColorAnim {}
    }

    Glyph {
        text: root.previousSymbol
        opacity: 1 - root.progress
        scale: 1 - root.progress * 0.2
        visible: opacity > 0
    }

    Glyph {
        text: root.shownSymbol
        opacity: root.progress
        scale: 0.8 + root.progress * 0.2
    }

    Anim {
        id: swapAnim

        target: root
        property: "progress"
        from: 0
        to: 1
    }

    component Glyph: Text {
        anchors.centerIn: parent
        color: root.color
        font.family: Tokens.font.icon
        font.pixelSize: root.size
        font.variableAxes: ({
                "FILL": root.fillStep,
                "wght": root.weight,
                "GRAD": root.grade,
                "opsz": root.opticalSize
            })
        textFormat: Text.PlainText
        // Qt's default text renderer garbles this font's filled shapes, whose
        // outlines overlap. The native one draws them correctly.
        renderType: Text.NativeRendering
    }
}
