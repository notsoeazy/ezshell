import QtQuick
import qs.themes

// A small history line with a faint fill under it. `values` oldest first; `max` is the top of the scale
// (0 = the largest value shown, so rates that vary in size still fill the height). A Canvas, not a Shape:
// Shape sparklines inside the island froze the shell while it morphed between tab widths. Repaints only
// when the values or the size change.
Canvas {
    id: root

    property list<real> values: []
    property real max: 1
    property color color: Colors.primary
    readonly property real ceiling: root.max > 0 ? root.max : Math.max(...root.values, 1)

    function yAt(value: real): real {
        return root.height - Math.max(0, Math.min(1, value / root.ceiling)) * root.height;
    }

    implicitHeight: Appearance.island.dashboard.sparkline
    onValuesChanged: root.requestPaint()
    onWidthChanged: root.requestPaint()
    onHeightChanged: root.requestPaint()
    onColorChanged: root.requestPaint()
    onPaint: {
        const ctx = root.getContext("2d");
        ctx.reset();
        if (root.values.length < 2)
            return;
        const step = root.width / (root.values.length - 1);
        ctx.beginPath();
        ctx.moveTo(0, root.yAt(root.values[0]));
        for (let i = 1; i < root.values.length; i++)
            ctx.lineTo(i * step, root.yAt(root.values[i]));
        ctx.lineWidth = Appearance.island.dashboard.sparklineStroke;
        ctx.lineJoin = "round";
        ctx.strokeStyle = root.color;
        ctx.stroke();
        // The same line closed along the bottom, faintly filled.
        ctx.lineTo(root.width, root.height);
        ctx.lineTo(0, root.height);
        ctx.closePath();
        ctx.fillStyle = Qt.alpha(root.color, Appearance.island.dashboard.sparklineFill);
        ctx.fill();
    }
}
