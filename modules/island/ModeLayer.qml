import QtQuick
import qs.components
import qs.themes

// One island view. Fades out fast when its mode ends, and fades in once the morph is partly done
// (docs/ISLAND.md, Motion). Interrupted transitions continue from the current opacity.
Loader {
    id: root

    required property bool shown
    // Keep the item loaded while hidden (the resting view, whose width sizes the pill).
    property bool persistent: false
    property int fadeInDelay: 0

    active: root.persistent
    opacity: 0
    visible: opacity > 0

    states: State {
        name: "shown"
        when: root.shown

        PropertyChanges {
            root.active: true
            root.opacity: 1
        }
    }

    transitions: [
        Transition {
            to: "shown"

            SequentialAnimation {
                PropertyAction {
                    property: "active"
                }

                PauseAnimation {
                    duration: root.fadeInDelay
                }

                Anim {
                    property: "opacity"
                    duration: Appearance.anim.scaled(Appearance.anim.islandFadeIn)
                }
            }
        },
        Transition {
            from: "shown"

            SequentialAnimation {
                Anim {
                    property: "opacity"
                    duration: Appearance.anim.scaled(Appearance.anim.islandFadeOut)
                }

                PropertyAction {
                    property: "active"
                }
            }
        }
    ]
}
