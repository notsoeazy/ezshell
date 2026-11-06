import QtQuick
import qs.themes

NumberAnimation {
    duration: Appearance.anim.scaled(Appearance.anim.normal)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.standard
}
