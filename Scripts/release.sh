#!/bin/sh
# Archive with Developer ID, notarize using Keychain credentials, and package.
set -eu
cd "$(dirname "$0")/.."
mode="${1:-archive}"
archive_path="$PWD/.build/release/RemoteStatsMonitor.xcarchive"
export_path="$PWD/dist/release"
case "$mode" in
    archive)
        python3 Scripts/generate_project.py
        xcodebuild -project RemoteStatsMonitor.xcodeproj -scheme RemoteStatsMonitor \
            -configuration Release -archivePath "$archive_path" \
            -derivedDataPath .build/release/DerivedData -destination 'generic/platform=macOS' \
            CODE_SIGN_IDENTITY='Developer ID Application' \
            CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO OTHER_CODE_SIGN_FLAGS=--timestamp \
            archive
        ;;
    submit)
        profile="${2:-remote-stats-monitor}"
        archive_app="$archive_path/Products/Applications/Remote Stats Monitor.app"
        codesign --verify --deep --strict --verbose=2 "$archive_app"
        ditto -c -k --sequesterRsrc --keepParent "$archive_app" .build/release/notarization.zip
        xcrun notarytool submit .build/release/notarization.zip \
            --keychain-profile "$profile" --wait --timeout 15m
        ;;
    export)
        mkdir -p "$export_path"
        ditto "$archive_path/Products/Applications/Remote Stats Monitor.app" "$export_path/Remote Stats Monitor.app"
        xcrun stapler staple "$export_path/Remote Stats Monitor.app"
        ;;
    package)
        app="$export_path/Remote Stats Monitor.app"
        codesign --verify --deep --strict --verbose=2 "$app"
        xcrun stapler validate "$app"
        spctl --assess --type execute --verbose=2 "$app"
        version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")
        archive="$export_path/Remote-Stats-Monitor-$version-macOS.zip"
        ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
        (cd "$export_path" && shasum -a 256 "Remote-Stats-Monitor-$version-macOS.zip" > SHA256SUMS.txt)
        printf 'Release package: %s\n' "$archive"
        ;;
    *) printf 'Usage: sh Scripts/release.sh [archive|submit|export|package]\n' >&2; exit 1 ;;
esac
