#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p .build/checks
set --
for source in $(find Widget -type f -name '*.swift' -print | sort); do
    case "$source" in Widget/App/RemoteStatsMonitorWidget.swift) ;; *) set -- "$@" "$source" ;; esac
done
xcrun swiftc -swift-version 6 -target "$(uname -m)-apple-macos26" Core/Models/MonitorSnapshot.swift Core/Models/RemoteProcess.swift Core/Models/MonitorError.swift Core/Persistence/SnapshotStore.swift Core/WidgetIntegration/WidgetServerSource.swift Shared/Dashboard/*.swift Shared/Metrics/*.swift Shared/Models/*.swift Shared/Processes/*.swift Shared/Servers/*.swift Shared/Theme/*.swift "$@" Tests/Widgets/WidgetConfigurationChecks.swift -o .build/checks/widget-configuration-checks
.build/checks/widget-configuration-checks
