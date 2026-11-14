# ezshell

A Quickshell (QML) desktop shell for Hyprland built around a morphing island at
the top of the screen. `docs/` is the spec.

All fourteen phases of `docs/09-open-questions.md` are built; phase 14 is
specified in `docs/10-phase-14.md`.

Before writing or reviewing code, read:

- `docs/05-design-system.md` — tokens and the component inventory
- `docs/06-architecture.md` — directory layout and what may import what
- `docs/07-conventions.md` — numbered code rules; follow them and cite them
- `docs/02-island.md` — how the island and its views work (for later phases)

Hard rules:

- Pure QML. No C++ plugin, no `Caelestia.*` imports.
- No literal sizes, fonts, durations or curves outside
  `config/Tokens.qml`, and no literal colours outside `theme/`. Colours come from
  `Theme.color` (the shell's roles); use `Theme.material` (the wallpaper's
  Material palette) only when no role fits.
- Tokens over defaults: a control's size is a size token
  (`size: Tokens.size.lg`), never the component's own enum or a number.
- Components never import services or modules; services contain no UI.
- Shared behaviour lives in a base component (`Pressable`, `Reveal`, `Morph`,
  `View`), never copied between features.
- Fonts are Geist (vendored in `assets/fonts/`) and Material Symbols Rounded
  (the system package `ttf-material-symbols-variable`; never vendor it). The
  launcher's symbol mode also draws with the vendored Symbols Nerd Font. No
  Apple fonts.
- All glyphs go through the `Icon` component, by Material Symbols name; never
  a codepoint or the icon font family in feature code.
- A behaviour change updates the matching doc in the same commit.

Run with `qs -p .`. Caelestia (`~/.config/quickshell/caelestia`) is the reference
implementation for patterns, not a dependency.
