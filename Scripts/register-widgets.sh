#!/bin/sh
# Select one local build so stale copies do not compete in the widget gallery.
set -eu
cd "$(dirname "$0")/.."
configuration="${1:-Release}"
case "$configuration" in
    Debug) app="$(pwd)/dist/Remote Stats Monitor Debug.app" ;;
    Release) app="$(pwd)/dist/Remote Stats Monitor.app" ;;
    *) printf 'Usage: sh Scripts/register-widgets.sh [Debug|Release]\n' >&2; exit 1 ;;
esac
extension='Contents/PlugIns/RemoteStatsMonitorWidget.appex'
[ -d "$app/$extension" ] || { printf 'Build %s first.\n' "$configuration" >&2; exit 1; }
for copy in "$(pwd)/dist/Remote Stats Monitor Debug.app" "$(pwd)/dist/Remote Stats Monitor.app" "$(pwd)/.build/Build/Products/Debug/Remote Stats Monitor.app" "$(pwd)/.build/Build/Products/Release/Remote Stats Monitor.app"; do
    if [ "$copy" != "$app" ] && [ -d "$copy/$extension" ]; then
        /usr/bin/pluginkit -r "$copy/$extension"
    fi
done
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
/usr/bin/pluginkit -a "$app/$extension"
/usr/bin/pluginkit -e use -i dev.anuz.RemoteStatsMonitorWidget
/usr/bin/pluginkit -m -v -i dev.anuz.RemoteStatsMonitorWidget
