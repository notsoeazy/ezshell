pragma Singleton

import QtQuick
import Quickshell

// What the Theme service needs to know about matugen: its scheme names, how its roles map to ours, and
// which pairs must stay readable. Pure data and functions; the Theme service runs matugen.
Singleton {
    id: root

    readonly property list<string> schemes: root.schemeList()
    // [foreground, background (null = the black island), minimum WCAG ratio]: 4.5 for text, 3 for accents.
    readonly property var pairs: root.contrastPairs()
    // matugen role → our role. Theme forces surface to black after mapping.
    readonly property var roles: ({
            surface: "surface",
            on_surface: "surfaceFg",
            on_surface_variant: "surfaceVariantFg",
            surface_container: "surfaceContainer",
            surface_container_high: "surfaceContainerHigh",
            surface_container_highest: "surfaceContainerHighest",
            primary: "primary",
            on_primary: "primaryFg",
            primary_container: "primaryContainer",
            on_primary_container: "primaryContainerFg",
            secondary: "secondary",
            on_secondary: "secondaryFg",
            secondary_container: "secondaryContainer",
            on_secondary_container: "secondaryContainerFg",
            tertiary: "tertiary",
            tertiary_container: "tertiaryContainer",
            on_tertiary_container: "tertiaryContainerFg",
            outline: "outline",
            outline_variant: "outlineVariant",
            error: "error",
            on_error: "errorFg",
            error_container: "errorContainer",
            on_error_container: "errorContainerFg"
        })

    function schemeList(): list<string> {
        const names = ["tonal-spot", "content", "expressive", "fidelity", "fruit-salad"];
        names.push("monochrome", "neutral", "rainbow", "vibrant");
        return names.map(n => `scheme-${n}`);
    }

    function contrastPairs(): var {
        const text = 4.5;
        const accent = 3;
        const pairs = [["surfaceFg", "surface", text], ["surfaceVariantFg", "surface", text]];
        pairs.push(["surfaceFg", "surfaceContainerHigh", text], ["primaryFg", "primary", text]);
        pairs.push(["primaryContainerFg", "primaryContainer", text]);
        pairs.push(["secondaryContainerFg", "secondaryContainer", text]);
        pairs.push(["tertiaryContainerFg", "tertiaryContainer", text], ["errorFg", "error", text]);
        pairs.push(["primary", null, accent], ["error", null, accent]);
        return pairs;
    }

    // matugen's `--json hex` output (dark variant) laid over `base`, so roles matugen lacks keep their value.
    function toPalette(json: var, base: var): var {
        const palette = Object.assign({}, base);
        for (const [from, to] of Object.entries(root.roles)) {
            const value = json.colors?.[from]?.dark?.color;
            if (value)
                palette[to] = value;
        }
        return palette;
    }
}
