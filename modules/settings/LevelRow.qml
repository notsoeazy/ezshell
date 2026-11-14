import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.components.containers
import qs.components.controls

// A row that sets a level: a slider and the value in words. Anything put
// inside (a mute button) follows the value.
ListRow {
    id: root

    property real value
    property real from: 0
    property real to: 1
    property real step: 0.05
    // The value as shown; a percentage unless set.
    property string text: `${Math.round((value - from) / (to - from) * 100)}%`

    signal moved(value: real)

    interactive: false

    Slider {
        value: root.value
        from: root.from
        to: root.to
        step: root.step
        disabled: root.disabled
        onMoved: value => root.moved(value)
    }

    Label {
        Layout.preferredWidth: Tokens.spacing.xxxl * 2
        text: root.text
        horizontalAlignment: Text.AlignRight
        tabular: true
        level: Label.Secondary
    }
}
