import QtQuick
import qs.config

// The only way to animate a colour. Never give it a spatial style: overshoot
// on a colour produces out-of-range flashes.
ColorAnimation {
    property Tokens.AnimStyle style: Tokens.motion.effects

    duration: style.duration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: style.curve
}
