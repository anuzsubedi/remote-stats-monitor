# Diagnostics

## Widget gallery or blank content

Check `pluginkit -m -v -i dev.anuz.RemoteStatsMonitorWidget` to identify the active extension. Multiple local app copies can compete. `Scripts/register-widgets.sh` selects a project build for development; distribution builds belong in Applications.

Inspect logs from `chronod` and `RemoteStatsMonitorWidget` for descriptor, placeholder, and timeline failures. Successful compilation alone does not establish a working extension. A previous interpolated widget description caused a runtime assertion; descriptions now use static strings, and `Scripts/check-widgets.sh` constructs the actual configurations.

## Connections

Saved credentials are in Keychain under service `dev.anuz.RemoteStatsMonitor.connection`. `--diagnose-storage` reports only record counts and differing field names. Never dump passwords into issue reports.

Startup consolidates equivalent saved connections and reconciles widget IDs. Explicit SSH ports stay distinct from ports resolved by SSH configuration. Missing snapshots show an empty state; SSH failures retain the previous reading with an error state.

## Debug samples

Debug-only samples use a separate App Group cache. They survive Debug restarts until removed and never create credentials or SSH sessions. Release builds exclude sample controls and sample data sources.

## GPU

GPU collection is optional and defaults off. Unsupported drivers or missing telemetry dependencies produce a dash. The collector does not install Python or packages, escalate privileges, or infer utilization from clock speed. Test fixtures cover V3D deltas, DRM shared-descriptor deduplication, multiple devices, idle readings, and disabled sampling.

## Validation limits

The isolated checks cover models, stores, connection parsing, collectors, widget configuration, and navigation. Native preview renders check layout. Hardware support depends on the remote kernel, driver, permissions, and available commands; fixture coverage does not establish behavior on every GPU. WidgetKit controls desktop refresh scheduling.
