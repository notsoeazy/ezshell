import QtQuick

// A Material palette for one appearance, with Material's role names (the
// same names matugen and Caelestia use), plus the sixteen terminal colours.
// Filled in from the palette generated from the wallpaper; see Theme.
QtObject {
    // Surfaces and what sits on them
    property color background
    property color onBackground
    property color surface
    property color surfaceDim
    property color surfaceBright
    property color surfaceContainerLowest
    property color surfaceContainerLow
    property color surfaceContainer
    property color surfaceContainerHigh
    property color surfaceContainerHighest
    property color onSurface
    property color surfaceVariant
    property color onSurfaceVariant
    property color outline
    property color outlineVariant
    property color inverseSurface
    property color inverseOnSurface
    property color inversePrimary
    property color shadow
    property color scrim
    property color surfaceTint
    property color sourceColor

    // Primary: the accent
    property color primary
    property color onPrimary
    property color primaryContainer
    property color onPrimaryContainer
    property color primaryFixed
    property color primaryFixedDim
    property color onPrimaryFixed
    property color onPrimaryFixedVariant

    // Secondary: quieter than the accent
    property color secondary
    property color onSecondary
    property color secondaryContainer
    property color onSecondaryContainer
    property color secondaryFixed
    property color secondaryFixedDim
    property color onSecondaryFixed
    property color onSecondaryFixedVariant

    // Tertiary: a contrasting accent
    property color tertiary
    property color onTertiary
    property color tertiaryContainer
    property color onTertiaryContainer
    property color tertiaryFixed
    property color tertiaryFixedDim
    property color onTertiaryFixed
    property color onTertiaryFixedVariant

    // Error
    property color error
    property color onError
    property color errorContainer
    property color onErrorContainer

    // Terminal colours 0 to 15
    property color term0
    property color term1
    property color term2
    property color term3
    property color term4
    property color term5
    property color term6
    property color term7
    property color term8
    property color term9
    property color term10
    property color term11
    property color term12
    property color term13
    property color term14
    property color term15
}
