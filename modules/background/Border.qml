pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.theme
import qs.components

// A frame of the island's colour around the edge of every screen, with rounded
// inner corners. It is drawn above every window (a window moved over the edge
// goes under it) but below the island, which is on the overlay layer; a
// fullscreen window covers it. It takes no input, and its thickness is kept clear of windows (one ExclusiveZone per
// edge). The island hangs from its inner top edge (see IslandWindow).
// Thickness 0 turns it off.
Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        // qmllint disable uncreatable-type
        PanelWindow {
            // qmllint enable uncreatable-type
            screen: scope.modelData
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: Config.border.thickness > 0
            WlrLayershell.namespace: "ezshell-border"
            WlrLayershell.layer: WlrLayer.Top

            mask: Region {}

            Shape {
                id: frame

                readonly property real edge: Config.border.thickness
                // Never more than half of what is left inside the frame.
                readonly property real round: Math.max(0, Math.min(Config.border.rounding, (width - edge * 2) / 2, (height - edge * 2) / 2))

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: -1
                    fillColor: Theme.color.island
                    fillRule: ShapePath.OddEvenFill
                    startX: 0
                    startY: 0

                    // The screen.
                    PathLine {
                        x: frame.width
                        y: 0
                    }

                    PathLine {
                        x: frame.width
                        y: frame.height
                    }

                    PathLine {
                        x: 0
                        y: frame.height
                    }

                    PathLine {
                        x: 0
                        y: 0
                    }

                    // The hole, with rounded corners.
                    PathMove {
                        x: frame.edge + frame.round
                        y: frame.edge
                    }

                    PathLine {
                        x: frame.width - frame.edge - frame.round
                        y: frame.edge
                    }

                    PathArc {
                        x: frame.width - frame.edge
                        y: frame.edge + frame.round
                        radiusX: frame.round
                        radiusY: frame.round
                    }

                    PathLine {
                        x: frame.width - frame.edge
                        y: frame.height - frame.edge - frame.round
                    }

                    PathArc {
                        x: frame.width - frame.edge - frame.round
                        y: frame.height - frame.edge
                        radiusX: frame.round
                        radiusY: frame.round
                    }

                    PathLine {
                        x: frame.edge + frame.round
                        y: frame.height - frame.edge
                    }

                    PathArc {
                        x: frame.edge
                        y: frame.height - frame.edge - frame.round
                        radiusX: frame.round
                        radiusY: frame.round
                    }

                    PathLine {
                        x: frame.edge
                        y: frame.edge + frame.round
                    }

                    PathArc {
                        x: frame.edge + frame.round
                        y: frame.edge
                        radiusX: frame.round
                        radiusY: frame.round
                    }

                    Behavior on fillColor {
                        ColorAnim {}
                    }
                }
            }
        }

        ExclusiveZone {
            screen: scope.modelData
            edge: "top"
            size: Config.border.thickness
        }

        ExclusiveZone {
            screen: scope.modelData
            edge: "bottom"
            size: Config.border.thickness
        }

        ExclusiveZone {
            screen: scope.modelData
            edge: "left"
            size: Config.border.thickness
        }

        ExclusiveZone {
            screen: scope.modelData
            edge: "right"
            size: Config.border.thickness
        }
    }
}
