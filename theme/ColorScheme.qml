import QtQuick

// One appearance's colour values. Tokens holds a light and a dark instance;
// everything else reads the active one through Tokens.color.
QtObject {
    // Surfaces
    required property color surface
    required property color surfaceRaised
    required property color island
    required property color scrim

    // Content, by vibrancy level
    required property color label
    required property color labelSecondary
    required property color labelTertiary
    required property color labelQuaternary
    required property color fill
    required property color fillSecondary
    required property color fillTertiary
    required property color separator
    // The raised part of a control: selected segment, switch and slider thumbs.
    required property color control
    // A switch's thumb while off, and a slider's thumb.
    required property color thumb
    // Text and icons on top of the accent or a system colour.
    required property color onAccent

    // System colours
    required property color blue
    required property color green
    required property color red
    required property color orange
    required property color yellow
    required property color indigo
    required property color purple
    required property color pink
    required property color teal
    required property color grey

    // Roles
    readonly property color destructive: red
    readonly property color success: green
    readonly property color warning: orange
}
