# Theming

- Themes (`ThemeID`, menu order): Frost (default), System, Opal, Graphite Pro, One Dark Pro, Quartz Pro.
  Chosen from the status items' right-click menu (Theme ▸); saved as `appearance.theme` in the app's own defaults
  (Dev and Release apart). An unknown saved id reads as Frost. A change applies to the next panel opened.
- `PanelPalette` (UI) holds every panel colour and the window's surface; `PanelTheme` only metrics and type.
  Views read `@Environment(\.panelPalette)`; never a theme id, never hard-coded colours.
- Frost and System: system colours over a material (`.hudWindow` / `.popover`), light or dark with the system.
- Opal, Graphite Pro, One Dark Pro (dark) and Quartz Pro (light): their own colours on a
  near-opaque base over the material; the window's appearance is forced to match.
- The material's mask rounds only the material; `PanelContainer` rounds the theme's surface itself.
- Reduce Transparency: `NSVisualEffectView` turns solid on its own. Menu-bar items keep system colours in every theme.

## Adding a theme
1. A `ThemeID` case (stable raw value) and its title in `MetricStatusItem.title(_:)`, English and Polish.
2. Its palette in `PanelPalette.make`: `frosted(material:)` or `solid(Tones(...))`.
3. A test if it forces an appearance; check light and dark, Increase Contrast, Reduce Transparency.
