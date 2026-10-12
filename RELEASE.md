# Release process

Releases are universal macOS apps (Apple Silicon and Intel), requiring macOS 26 or later. The app and widget share version and build numbers. Source tags use `v<CFBundleShortVersionString>`.

## Validate and archive

```sh
sh Scripts/check.sh
sh Scripts/build.sh Debug
sh Scripts/release.sh archive
```

Archiving uses the installed **Developer ID Application** identity, the hardened runtime, and secure timestamps. It does not embed debug signing entitlements. The archive is created under `.build/release/`.

## Notarize

Store an Apple notarization credential profile locally with `xcrun notarytool store-credentials remote-stats-monitor --team-id 8UV7A5D64G`, then:

```sh
sh Scripts/release.sh submit
sh Scripts/release.sh export
sh Scripts/release.sh package
```

Submission uses the `remote-stats-monitor` Keychain profile; an alternative profile can be supplied as the second argument to `submit`. No account passwords or API keys belong in this repository. After Apple accepts the submission, export staples the notarization ticket. Packaging requires a valid stapled ticket and a successful Gatekeeper assessment, and writes a ZIP and SHA-256 checksum to `dist/release/`.

Never put passwords in release notes, shell history, or source files. A Developer ID signature alone is not proof of notarization.

## Publish

Commit the tested source and icon, create the matching annotated version tag, and attach the verified ZIP and `SHA256SUMS.txt` to its GitHub Release. Never upload `.build`, provisioning profiles, private keys, Keychain data, or server snapshots.
