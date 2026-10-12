---
name: Remote Stats Monitor
description: Native macOS server monitoring surfaces
typography:
  body:
    fontFamily: SF Pro
    fontWeight: 400
  reading:
    fontFamily: SF Pro
    fontWeight: 600
spacing:
  compact: 8px
  control: 12px
  panel: 16px
  window: 24px
rounded:
  selection: 9px
  panel: 12px
---

## Overview

This is an operating interface for checking remote Linux servers over SSH. Native macOS typography, controls, semantic surfaces, and system appearance govern every screen. The minimum macOS version is 26. The app icon remains a single charcoal telemetry glyph on neutral off-white, compiled directly from `AppIcon.icon`.

## Colors

Use SwiftUI semantic foregrounds (`.primary`, `.secondary`), native backgrounds, and `Color.accentColor`. Accent identifies selection and measured usage. Orange marks warning conditions and accompanies a status label or symbol. Connected state uses green with text; never rely on color alone. Respect light, dark, and system widget rendering.

## Typography

Use SF system styles for UI. Server names lead; status and timestamps sit beneath. Metric values use monospaced digits, consistent precision, and a single line. Missing readings show a dash. Truncate long host names in the middle, preserving identifying suffixes. Labels remain distinct from numeric values.

## Layout

The main window uses one scene-level navigation split view with Overview, Servers, Processes, and Settings destinations. Overview shows the selected server. Servers uses the full content area for a searchable list or grid; opening a server pushes its detail with a native Back action. Native toolbars own the top safe area, without nested split views below custom headers. The menu defaults to the selected server and exposes Server, List, and Grid layouts. New connections become selected automatically.

The selected detail uses a two-column metric layout, supporting capacity totals, GPU availability, uptime, and processes. Menu fleet rows retain CPU, GPU, temperature, and memory readings. Window content scrolls as needed; primary connection actions stay outside the scrolling form.

Widgets use one native Liquid Glass container surface, with an opaque system-background fallback when Reduce Transparency is enabled. Metrics remain unboxed above the glass. Widgets have deliberate layouts for small, medium, and large sizes. Fleet widgets cap medium layouts at four servers and large layouts at eight. Preserve meaningful metric and server labels at compact sizes.

## Elevation & Depth

Use native system materials and control treatments. Divide regions with spacing and subtle separators. Avoid decorative shadows, gradients, and layered cards. Selection should remain legible without overpowering the data.

## Shapes

Use native button shapes. Rounded selection regions and data panels use modest corner radii. Usage scales encode actual measurements; they are not decoration or invented history.

## Components

- Server headers expose state and context before metrics. Use direct Refresh and Edit actions; server switching uses a compact, labeled menu without a duplicate disclosure indicator.
- Server nicknames are optional and fall back to the SSH address. A curated SF Symbols grid selects the server icon. Preserve identity across app and widget surfaces without changing the SSH destination.
- Settings contain actionable preferences; omit static catalogs of widget types.
- Single-server widgets use only previous and next arrows around the server name. System Edit Widget selects a configured server; do not add an inline selector.
- Forms use grouped sections, explicit field labels, inline errors, and native authentication controls. GPU collection remains optional and off by default.
- Processes use aligned numeric columns and clear empty/search states.
- Widget descriptions must be static string literals; interpolated descriptions can crash WidgetKit gallery registration.
- Debug samples remain visibly identified and separate from saved SSH credentials.

## Do's and Don'ts

Keep copy concrete, keyboard controls accessible, and unavailable or old readings distinguishable from fresh values. Preserve the minimal icon. Do not invent telemetry, hide missing sensors as zero, add marketing copy, or promise real-time WidgetKit refreshes.

Verify actual app and widget layouts in both system appearances, compact window sizes, and all supported widget sizes. Offscreen NSHostingView previews check layout but do not reproduce the desktop compositor or prove interactive WidgetKit behavior.
