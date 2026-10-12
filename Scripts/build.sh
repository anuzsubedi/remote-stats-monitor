#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
build_configuration="${1:-Release}"
case "$build_configuration" in
    Debug) output_app='dist/Remote Stats Monitor Debug.app' ;;
    Release) output_app='dist/Remote Stats Monitor.app' ;;
    *) printf 'Usage: sh Scripts/build.sh [Debug|Release]\n' >&2; exit 1 ;;
esac
python3 Scripts/generate_project.py
xcodebuild -project RemoteStatsMonitor.xcodeproj -scheme RemoteStatsMonitor -configuration "$build_configuration" -derivedDataPath .build build
mkdir -p dist
ditto ".build/Build/Products/$build_configuration/Remote Stats Monitor.app" "$output_app"
printf '\nBuilt %s\n' "$output_app"
