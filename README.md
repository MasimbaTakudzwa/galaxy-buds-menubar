# Buddy

Mac menubar companion for Galaxy Buds 3 FE. Personal-use, open source.

## Goals

- Battery, ANC mode, and EQ from the menubar — no Samsung app needed
- Auto-reconnect on wake, auto-pause when buds are removed
- Smooth iPhone ↔ MacBook handoff via iOS Shortcuts (later phase)

## Status

Skeleton. The protocol layer is stubbed — opcodes need verification against
packet captures from Buds 3 FE before any real command works. See
[ThePBone/GalaxyBudsClient](https://github.com/ThePBone/GalaxyBudsClient) for
the closest existing protocol reference (older Buds models).

## Build

Requires macOS 14+, Swift 5.10 / Xcode 15+.

```sh
swift build
swift run Buddy
```

A "Buddy" earbud icon appears in the menubar. The connection layer is a stub
right now — the menu shows "No buds connected".

### Tests

Tests are written with [Swift Testing](https://developer.apple.com/xcode/swift-testing/)
and require full Xcode (Command Line Tools alone do not bundle the `Testing` /
`XCTest` modules). The test target is currently commented out in
`Package.swift` — uncomment it once Xcode is installed, then:

```sh
swift test
```

## Layout

| Module             | Purpose                                              |
| ------------------ | ---------------------------------------------------- |
| `Buddy`            | Executable: menubar app entry, status item, settings |
| `BudsProtocol`     | Frame format + codec for the Samsung MGR protocol    |
| `BudsTransport`    | RFCOMM (IOBluetooth) and BLE GATT (CoreBluetooth)    |
| `BudsCore`         | Domain model + connection manager actor              |
| `BudsFeatures`     | ANC, EQ, touch options, find-my-buds, auto-pause     |
| `BudsUI`           | Reusable SwiftUI components                          |

## Next milestones

1. Capture real Buds 3 FE traffic with `PacketLogger.app` and confirm framing
2. Open RFCOMM channel + decode the battery message → render in menubar
3. Send the ANC-cycle command → first outbound write
4. Auto-reconnect on wake, auto-pause on wear-detection event
5. EQ preset switching + Settings window (SwiftUI three-pane)
6. Handoff layer: iOS Shortcut + Mac coordinator

## License

GPL-3.0-or-later, matching the upstream protocol reference work in
[ThePBone/GalaxyBudsClient](https://github.com/ThePBone/GalaxyBudsClient).
If everything ends up re-derived from your own packet captures, the project
can be relicensed to MIT.
