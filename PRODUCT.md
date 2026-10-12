# Product

<!-- impeccable:product-schema 1 -->

## Platform

macOS

## Stack

SwiftUI menu bar app with a WidgetKit extension; implementation delegated to the project.

## Users

People who run a Raspberry Pi and want to check its health from their Mac.

## Product Purpose

Show the Raspberry Pi's current CPU load, temperature, memory, and disk usage from a macOS menu bar app and desktop widget.

## Positioning

The Mac connects to the Pi over SSH. Users enter their SSH connection details and can save credentials in macOS Keychain.

## Operating Context

The user checks a Pi 5 from the Mac menu bar or desktop. Widget data is refreshed by the companion app and shared with the WidgetKit extension.

## Capabilities and Constraints

- Initial target is Raspberry Pi 5 over SSH.
- Initial metrics are CPU, temperature, memory, and disk usage.
- Connection details include SSH host, user, and port. Password or SSH key authentication must be supported; saved secrets belong in Keychain.
- WidgetKit refresh timing is system controlled; exact real-time updates are not promised.
- macOS 26 or later is required for Liquid Glass.
- Password authentication through Keychain, host-key pinning, live metric collection, and shared widget cache writes have been verified against the user's Pi. SSH key authentication is implemented but still needs a physical-device check.

## Brand Commitments

Native macOS UI throughout: Liquid Glass, system typography, native controls, SF Symbols, and system appearance. Preserve the approved B layout with four metrics in a 2 by 2 grid. The earlier cream and green comp palette is superseded by the native macOS requirement.

## Evidence on Hand

Physical SSH password authentication and live CPU, temperature, memory, and disk readings were verified. Credentials remain in Keychain and telemetry stays in the Mac's shared app group container; neither belongs in the repository. Repository screenshots and test fixtures use explicitly labelled sample data.

## Product Principles

- Make health and connection state readable at a glance.
- Keep connection credentials in Keychain.
- Label stale or unavailable readings clearly.
