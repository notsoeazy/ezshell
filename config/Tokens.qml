pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Design tokens (docs/05-design-system.md): every size, font, duration and
// curve. Colours live in qs.theme. Literal values may appear only in this file
// and the theme.
Singleton {
    id: root

    readonly property FontTokens font: FontTokens {}
    readonly property FontSizeTokens fontSize: FontSizeTokens {}
    readonly property FontWeightTokens fontWeight: FontWeightTokens {}
    readonly property SpacingTokens spacing: SpacingTokens {}
    readonly property RadiusTokens radius: RadiusTokens {}
    readonly property ControlTokens control: ControlTokens {}
    readonly property IconTokens icon: IconTokens {}
    readonly property StateTokens state: StateTokens {}
    // Control sizes: height, icon, padding and text that go together.
    readonly property SizeTokens size: SizeTokens {
        control: root.control
        icon: root.icon
        spacing: root.spacing
        fontSize: root.fontSize
    }
    readonly property IslandTokens island: IslandTokens {}
    readonly property LockTokens lock: LockTokens {}
    readonly property MotionTokens motion: MotionTokens {
        scale: Config.appearance.animationScale
        reduce: Config.appearance.reduceMotion
    }

    // Radius for a rounded item inset by `padding` inside a rounded container.
    function concentric(outer: real, padding: real): real {
        return Math.max(0, outer - padding);
    }

    // The value types tokens are made of. Other files name them through the
    // singleton: `property Tokens.ControlSize size`.

    // A duration paired with a bezier curve, in the form easing.bezierCurve takes:
    // [x1, y1, x2, y2, 1, 1].
    component AnimStyle: QtObject {
        required property int duration
        required property list<real> curve
    }

    // One size a control can be: everything that should change together when a
    // control gets bigger. Controls take one of these (from Tokens.size) instead
    // of a size name of their own, so the same four sizes mean the same thing on
    // every control and a slider lines up with the button beside it.
    component ControlSize: QtObject {
        // The control's height.
        required property real height
        // Icon inside it.
        required property real icon
        // Space between the control's edge and its content, left and right.
        required property real padding
        // Text inside it.
        required property real fontSize
    }

    // The groups. Each is its own type so its members are typed for the linter.

    // Font families. Geist is loaded in shell.qml from assets/fonts; the icon
    // font is installed on the system.
    component FontTokens: QtObject {
        readonly property string family: "Geist"
        readonly property string mono: "Geist Mono"
        // Nerd Font glyphs (vendored), for the launcher's symbol mode.
        readonly property string nerd: "Symbols Nerd Font"
        // From the system package ttf-material-symbols-variable, not vendored.
        readonly property string icon: "Material Symbols Rounded"
        // The range of sizes the icon font has tuned drawings for.
        readonly property real iconOpticalMin: 20
        readonly property real iconOpticalMax: 48
    }

    // Font sizes, one step apart on the macOS scale and each one larger than
    // Apple's (body is 15, not 13). Named like spacing. Clocks have their own
    // sizes in `island` and `lock`.
    component FontSizeTokens: QtObject {
        readonly property real xs: 10
        readonly property real sm: 13
        readonly property real md: 16
        readonly property real lg: 18
        readonly property real xl: 20
        readonly property real xxl: 26
    }

    // Font weights, as values on Geist's `wght` axis.
    component FontWeightTokens: QtObject {
        readonly property int regular: Font.Normal
        readonly property int medium: Font.Medium
        readonly property int semibold: Font.DemiBold
        readonly property int bold: Font.Bold
    }

    // Spacing on a 4pt grid.
    component SpacingTokens: QtObject {
        readonly property real xxs: 2
        readonly property real xs: 4
        readonly property real sm: 8
        readonly property real md: 12
        readonly property real lg: 16
        readonly property real xl: 20
        readonly property real xxl: 24
        readonly property real xxxl: 32
    }

    // Corner radii.
    component RadiusTokens: QtObject {
        readonly property real sm: 6
        readonly property real md: 10
        readonly property real lg: 16
        readonly property real xl: 22
        // Larger than any item, so Rectangle clamps it to a capsule.
        readonly property real full: 9999
    }

    // Control heights, named like the spacing, font and icon scales, and the
    // minimum pointer target.
    component ControlTokens: QtObject {
        readonly property real xs: 18
        readonly property real sm: 24
        readonly property real md: 28
        readonly property real lg: 32
        readonly property real xl: 36
        // The biggest button, and a slider that sits beside one.
        readonly property real xxl: 44
        readonly property real minTarget: 28
        // A row in a list: one line of text or two, so every row in a list is
        // the same height.
        readonly property real row: 48
        // Height of a control panel tile.
        readonly property real tile: 60
        // Thin slider and progress tracks, and the slider thumb.
        readonly property real track: 4
        readonly property real thumb: 20
        // The scrubber's bar, and how thick it gets while it is held.
        readonly property real bar: 6
        readonly property real barActive: 8
    }

    // Icon sizes, paired with text styles. Material Symbols carry their own
    // padding, so these run a little larger than the text beside them.
    component IconTokens: QtObject {
        readonly property real xs: 16
        readonly property real sm: 20
        readonly property real md: 24
        readonly property real lg: 30
        readonly property real xl: 36
    }

    // Interaction states: opacity of the highlight drawn over a control.
    component StateTokens: QtObject {
        readonly property real hover: 0.06
        readonly property real pressed: 0.12
        readonly property real disabled: 0.4
        readonly property real focusRing: 2
        // Background opacity of a tinted control.
        readonly property real tint: 0.15
        readonly property real pressScale: 0.97
        // How much larger the chosen one of a row of choices is drawn, such as
        // the wallpaper selector's.
        readonly property real chosenScale: 1.25
        // Scale content shrinks to as it fades out of a Morph, and grows from.
        readonly property real swapScale: 0.92
        // Hover time before a tooltip appears, in ms.
        readonly property int tooltipDelay: 600
        // Opacity of the accent behind selected text.
        readonly property real selection: 0.3
        // How strongly the accent tints the current row of a list.
        readonly property real current: 0.28
        // Half a text cursor blink, in ms.
        readonly property int cursorBlink: 530
        // How long a scrollbar stays visible after scrolling stops, in ms.
        readonly property int scrollbarHide: 800
    }

    // The sizes controls come in. Pass one to a control's `size`:
    // `Button { size: Tokens.size.xl }`.
    component SizeTokens: QtObject {
        id: group

        required property ControlTokens control
        required property IconTokens icon
        required property SpacingTokens spacing
        required property FontSizeTokens fontSize

        readonly property ControlSize sm: ControlSize {
            height: group.control.sm
            icon: group.icon.sm
            padding: group.spacing.sm
            fontSize: group.fontSize.sm
        }
        readonly property ControlSize md: ControlSize {
            height: group.control.md
            icon: group.icon.sm
            padding: group.spacing.md
            fontSize: group.fontSize.md
        }
        readonly property ControlSize lg: ControlSize {
            height: group.control.lg
            icon: group.icon.sm
            padding: group.spacing.md
            fontSize: group.fontSize.md
        }
        readonly property ControlSize xl: ControlSize {
            height: group.control.xl
            icon: group.icon.sm
            padding: group.spacing.md
            fontSize: group.fontSize.md
        }
        readonly property ControlSize xxl: ControlSize {
            height: group.control.xxl
            icon: group.icon.md
            padding: group.spacing.lg
            fontSize: group.fontSize.md
        }
    }

    // Island geometry.
    component IslandTokens: QtObject {
        // Height of the island at rest.
        readonly property real height: 40
        // Radius of the island's corners and shoulders.
        readonly property real radius: 20
        // How far below the screen's edge the island floats, as a pill, over a
        // fullscreen window.
        readonly property real floatGap: 12
        // Padding between the shape's edge and a view's content.
        readonly property real paddingX: 16
        readonly property real paddingY: 8
        readonly property real panelPadding: 16
        // Width of the control panel and its pages, so only the height changes
        // when moving between them.
        readonly property real panelWidth: 408
        // Width of the island for the tall views that have room to spread
        // (`hovered`, the notifications list, the launcher), so that moving
        // between them only changes the height. `sheetContentWidth` is what is
        // left for their content.
        readonly property real sheetWidth: 512
        readonly property real sheetContentWidth: sheetWidth - panelPadding * 2
        // Album art in the media controls.
        readonly property real mediaArt: 56
        // Font size of the `hovered` clock.
        readonly property real clockSize: 44
        // Width of one thumbnail in the wallpaper selector.
        readonly property real wallpaperThumb: 192
    }

    // Lock screen geometry.
    component LockTokens: QtObject {
        // Where the middle of the clock sits, as a part of the screen's height.
        readonly property real clockCenter: 0.2
        // Where the middle of the password field sits, likewise.
        readonly property real fieldCenter: 0.8
        readonly property real fieldWidth: 300
        // Font size of the clock.
        readonly property real clockSize: 112
    }

    // Motion styles. Spatial curves overshoot and are for position and size only;
    // effects curves are for opacity and colour.
    component MotionTokens: QtObject {
        id: group

        // Multiplies every duration.
        required property real scale
        // Drops the overshoot and caps spatial durations.
        required property bool reduce

        readonly property list<real> standardCurve: [0.2, 0, 0, 1, 1, 1]

        readonly property AnimStyle spatialFast: AnimStyle {
            duration: group.spatialDuration(350)
            curve: group.spatialCurve([0.42, 1.67, 0.21, 0.9, 1, 1])
        }
        readonly property AnimStyle spatial: AnimStyle {
            duration: group.spatialDuration(500)
            curve: group.spatialCurve([0.38, 1.21, 0.22, 1, 1, 1])
        }
        readonly property AnimStyle spatialSlow: AnimStyle {
            duration: group.spatialDuration(650)
            curve: group.spatialCurve([0.39, 1.29, 0.35, 0.98, 1, 1])
        }
        readonly property AnimStyle effectsFast: AnimStyle {
            duration: group.scaled(150)
            curve: [0.31, 0.94, 0.34, 1, 1, 1]
        }
        readonly property AnimStyle effects: AnimStyle {
            duration: group.scaled(200)
            curve: [0.34, 0.8, 0.34, 1, 1, 1]
        }
        readonly property AnimStyle effectsSlow: AnimStyle {
            duration: group.scaled(300)
            curve: [0.34, 0.88, 0.34, 1, 1, 1]
        }
        // Constant speed, for continuous loops such as spinners.
        readonly property AnimStyle linear: AnimStyle {
            duration: group.scaled(1000)
            curve: [0, 0, 1, 1, 1, 1]
        }
        // How long a value just set by dragging is held on screen while what it
        // moves catches up, in ms. A wait, not an animation.
        readonly property int settle: group.scaled(1000)
        // How long a notification reached from a click stays highlighted in the
        // list, in ms.
        readonly property int highlight: group.scaled(1500)
        readonly property AnimStyle standard: AnimStyle {
            duration: group.scaled(250)
            curve: group.standardCurve
        }

        function scaled(ms: int): int {
            return Math.round(ms * scale);
        }

        function spatialDuration(ms: int): int {
            return scaled(reduce ? Math.min(ms, 250) : ms);
        }

        function spatialCurve(curve: list<real>): list<real> {
            return reduce ? standardCurve : curve;
        }
    }
}
