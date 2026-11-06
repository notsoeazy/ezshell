pragma Singleton

import QtQuick
import Quickshell

// WCAG 2.1 contrast helpers for generated palettes.
Singleton {
    // Relative luminance of an sRGB color.
    function luminance(c: color): real {
        const channel = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
    }

    function ratio(a: color, b: color): real {
        const la = luminance(a);
        const lb = luminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // Moves fg toward white or black (whichever contrasts more with bg) in 10% steps until it reaches
    // `minimum`; returns fg unchanged when it already passes.
    function ensure(fg: color, bg: color, minimum: real): color {
        const white = Qt.color("#ffffff");
        const black = Qt.color("#000000");
        const target = ratio(white, bg) >= ratio(black, bg) ? white : black;
        let c = fg;
        for (let step = 1; step <= 10 && ratio(c, bg) < minimum; step++)
            c = Qt.tint(fg, Qt.alpha(target, step / 10));
        return c;
    }
}
