# Design

Remote Stats Monitor is a native macOS utility for checking remote Linux server readings. SwiftUI and WidgetKit supply system materials, semantic colors, and SF typography. The minimum macOS version is 26.

## App

The menu bar defaults to the selected server. Users can switch to list or grid layouts and open a larger server browser. Connection editing, process inspection, and Settings use native controls. Keep copy concrete, keyboard access clear, and errors attached to the relevant operation.

## Widgets

Overview widgets use a two-column metric grid with measured usage scales. Medium and large sizes show CPU, memory, GPU, and disk; small replaces disk with temperature. Large adds ranked processes. Individual metric widgets pair a value with a labeled 0–100 scale, using degrees Celsius for temperature.

Fleet lists align temperature, CPU, GPU, and memory columns. Fleet grids give each host a CPU scale and compact supporting readings. Process widgets rank by CPU with aligned memory values. Single-server headers place previous and next chevrons around a centered name; no inline selector or navigation footer.

Values use monospaced digits and remain on one line. Missing readings use a dash and empty scale. Orange indicates warning conditions, accompanied by status text or an SF Symbol. No historical data is invented. Backgrounds and secondary text adapt to light, dark, and system widget appearance.

## App icon

`AppIcon.icon` is the editable Icon Composer source. It contains a blue background, a three-bay server enclosure, and a separate mint telemetry layer. Xcode compiles it directly. Do not recreate a competing `AppIcon.appiconset`.

## Verification

Use native offscreen previews for small, medium, and large layout checks. These do not reproduce the desktop compositor or replace live WidgetKit verification. Configuration construction tests catch gallery metadata failures that content previews do not.
