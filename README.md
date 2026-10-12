# Remote Stats Monitor

A native macOS menu bar app and desktop widgets for monitoring multiple Linux servers over SSH. Requires macOS 26 or later; supports Apple Silicon and Intel Macs.

## Install

Download the ZIP from [GitHub Releases](https://github.com/anuzsubedi/remote-stats-monitor/releases), extract **Remote Stats Monitor.app**, and move it to Applications. Open it to add an SSH connection. The app runs in the menu bar, without a Dock icon.

## Features

- Monitor multiple servers concurrently, with selected-server, list, and grid views.
- CPU, memory, root disk, temperature, optional GPU utilization, and per-process readings.
- Nine desktop widgets: Server Overview, Server List, Server Grid, CPU, GPU, Memory, Disk, Temperature, and Processes.
- Fleet widgets show up to four servers at medium size or eight at large size.
- Single-server widgets use previous/next arrows. Use **Edit Widget** to set a specific server; widgets of the same type with the same configured server share their arrow navigation selection.
- Connections are restored and polled at launch. Enable launch at login in Settings if desired.

## Connect

Choose **Add server**, enter `username@hostname.local` or an SSH configuration alias, and choose SSH config, password, or a private key. Leaving Port blank lets OpenSSH resolve it from SSH configuration, otherwise defaulting to port 22. Verify the host-key fingerprint on first connection.

Credentials and passphrases are stored in macOS Keychain. Private keys remain in their original files. Widget storage contains only server labels and readings; it never contains SSH credentials. Widgets read cached snapshots and do not start SSH sessions.

The app polls approximately every five seconds while running. WidgetKit determines desktop refresh timing. Missing sensors show a dash; failed connections retain their last reading with a disconnected state. Authentication failures pause retries until corrected.

## GPU collection

GPU collection is **off by default**, including for previously saved connections. Enable **Collect GPU usage** in a server's connection settings and click **Connect** to save. Disabled collection skips all GPU commands and counter scans.

Supported sources include Raspberry Pi V3D counters, Linux DRM engine counters, AMD `gpu_busy_percent`, and NVIDIA `nvidia-smi`. Integrated, discrete, and external GPUs are supported when their driver exposes these counters. The display uses the busiest available GPU or engine. Pi/DRM sampling requires an existing Python 3 installation; DRM counters cover processes readable by the SSH user. NVIDIA sampling requires `timeout` and is bounded to one second. The app never installs software on the server.

## Build and test

Built with Xcode 27 and Swift 6. The project generator keeps the app and widget source membership in sync.

```sh
sh Scripts/check.sh
sh Scripts/build.sh Debug
open 'dist/Remote Stats Monitor Debug.app'
```

Set the signing team to your own Apple development team when building on another Mac. The app and widget must share an App Group. Tests use isolated stores and fake SSH/Keychain clients; they do not read your saved credentials.

Debug builds include eight synthetic servers with varied loads, missing sensors, and a disconnected example. **Add test servers** exposes them in both the app and widget picker. Samples persist across Debug restarts until removed, never use SSH or Keychain, and are excluded from Release builds.

`sh Scripts/register-widgets.sh Debug` selects a project build for local widget testing. Avoid running multiple installed copies with the same bundle identity.

## Source organization

- `App/`: application lifecycle, connection management, server browser, processes, settings, and previews.
- `Core/`: connection models, SSH execution, metric collection, persistence, and widget integration.
- `Shared/`: reusable presentation components and display models.
- `Widget/`: widget configuration, providers, navigation, and per-widget layouts.
- `Tests/`: isolated collector, connection, persistence, model, and widget checks.
- `AppIcon.icon/`: editable Icon Composer source, including vector artwork.
- `Scripts/`: project generation, builds, verification, and release packaging.

See [RELEASE.md](RELEASE.md) for Developer ID signing, notarization, and publishing steps. Local build products and signing credentials are excluded from Git.
