import QtQuick
import qs.theme

// The shell's own colour roles, taken from a Material palette. This is the
// one place that says which Material role each of ours is.
ColorScheme {
    id: root

    required property MaterialScheme material
    // The fixed scheme for the same appearance: the system colours stay as
    // they are, so red still means red on any wallpaper.
    required property ColorScheme base
    required property bool isDark

    surface: material.surface
    surfaceRaised: isDark ? material.surfaceContainerHigh : material.surfaceContainerLowest
    island: material.surfaceContainerLowest
    scrim: Qt.alpha(material.scrim, base.scrim.a)

    label: material.onSurface
    labelSecondary: material.onSurfaceVariant
    labelTertiary: material.outline
    labelQuaternary: material.outlineVariant
    fill: Qt.alpha(material.onSurface, isDark ? 0.2 : 0.14)
    fillSecondary: Qt.alpha(material.onSurface, isDark ? 0.16 : 0.1)
    fillTertiary: Qt.alpha(material.onSurface, isDark ? 0.12 : 0.07)
    separator: material.outlineVariant
    control: isDark ? material.outline : material.surfaceContainerLowest
    thumb: isDark ? material.outline : material.surfaceContainerLowest
    onAccent: material.onPrimary

    blue: base.blue
    green: base.green
    red: base.red
    orange: base.orange
    yellow: base.yellow
    indigo: base.indigo
    purple: base.purple
    pink: base.pink
    teal: base.teal
    grey: base.grey
}
