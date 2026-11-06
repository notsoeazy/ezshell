import QtQuick
import qs.themes

ColorAnimation {
    duration: Appearance.anim.scaled(Appearance.anim.normal)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.standard
}
