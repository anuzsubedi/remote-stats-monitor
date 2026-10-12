#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p .build/checks
python3 Scripts/generate_project.py >/dev/null
python3 Tests/Widgets/WidgetIntentTargetChecks.py
python3 Tests/Collectors/GPUChecks.py
xcrun swiftc -swift-version 6 Core/Connections/Connection.swift Core/Models/MonitorError.swift Core/Models/MonitorSnapshot.swift Core/Models/RemoteProcess.swift Core/Execution/ProcessExecution.swift Core/Execution/ProcessRunner.swift Core/Connections/SSHArguments.swift Tests/Collectors/CollectorChecks.swift -o .build/checks/collector-checks
.build/checks/collector-checks

xcrun swiftc -swift-version 6 -target "$(uname -m)-apple-macos26" Core/Connections/Connection.swift Core/Connections/HostKeyProposal.swift Core/Models/MonitorError.swift Core/Models/MonitorSnapshot.swift Core/Models/RemoteProcess.swift App/Connections/ServerSession.swift App/Connections/MonitorModel.swift Tests/Models/ModelChecks.swift -o .build/checks/model-checks
.build/checks/model-checks
xcrun swiftc -swift-version 6 Core/Connections/Connection.swift Core/Models/MonitorError.swift Core/Execution/ProcessExecution.swift Core/Execution/ProcessRunner.swift Core/Connections/SSHArguments.swift Tests/Connections/ConnectionChecks.swift -o .build/checks/connection-checks
.build/checks/connection-checks
xcrun swiftc -swift-version 6 -target "$(uname -m)-apple-macos26" Core/Models/MonitorError.swift Core/Models/RemoteProcess.swift Core/Models/MonitorSnapshot.swift Core/Persistence/SnapshotStore.swift Tests/Persistence/SnapshotStoreChecks.swift -o .build/checks/snapshot-store-checks
.build/checks/snapshot-store-checks
xcrun swiftc -swift-version 6 -target "$(uname -m)-apple-macos26" App/Navigation/AppNavigationSection.swift App/AppLifecycle/AppDelegate.swift Tests/AppLifecycle/LaunchChecks.swift -o .build/checks/launch-checks
.build/checks/launch-checks

xcrun swiftc -DDEBUG -swift-version 6 -target "$(uname -m)-apple-macos26" Core/Connections/Connection.swift Core/Connections/HostKeyProposal.swift Core/Models/MonitorError.swift Core/Models/MonitorSnapshot.swift Core/Models/RemoteProcess.swift App/Connections/ServerSession.swift App/Connections/MonitorModel.swift App/Connections/MonitorModel+Debug.swift Core/Persistence/DebugSnapshotStore.swift Core/Debug/SyntheticServers.swift Tests/Models/ModelChecks.swift -o .build/checks/debug-model-checks
.build/checks/debug-model-checks

xcrun swiftc -swift-version 6 Core/Connections/Connection.swift Core/Models/MonitorError.swift Core/Persistence/KeychainStore.swift Tests/Persistence/KeychainChecks.swift -o .build/checks/keychain-checks
.build/checks/keychain-checks

xcrun swiftc -swift-version 6 -target "$(uname -m)-apple-macos26" Widget/Configuration/WidgetServerAction.swift Tests/Widgets/WidgetNavigationChecks.swift -o .build/checks/widget-navigation-checks
.build/checks/widget-navigation-checks

sh Scripts/check-widgets.sh
