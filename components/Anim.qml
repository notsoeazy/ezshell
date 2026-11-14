import QtQuick
import qs.config

// The only way to animate a number. Takes a motion token: spatial styles for
// position and size, effects styles for opacity.
NumberAnimation {
    property Tokens.AnimStyle style: Tokens.motion.effects

    duration: style.duration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: style.curve
}
