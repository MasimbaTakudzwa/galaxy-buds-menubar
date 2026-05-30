# Buddy

Mac menubar companion for Galaxy Buds 3 FE. Personal-use, open source.

A native macOS app that talks Samsung's Galaxy Buds protocol directly over
Bluetooth — battery, ANC, and EQ from the menubar, with an AirPods-style
connect popup — no Samsung app or phone needed.

## Status

Working read path, in-progress control path.

- ✅ **BLE detection** — fires an AirPods-style Connect HUD when you open the case
- ✅ **Classic-BT connect** detection (the right trigger for a paired setup)
- ✅ **RFCOMM control channel** (Samsung `GEARMANAGER`, ch 27)
- ✅ **Live battery** — Left / Right / Case decoded from the status frame and
  shown in the menubar panel + HUD (verified against hardware)
- ✅ **Verified frame encoder** (CRC-16/XMODEM) — can build valid commands
- 🟡 **ANC + EQ control** — wired to send, but the Buds 3 FE opcodes are still
  candidates pending hardware confirmation (see `TESTING.md`)
- ⬜ Auto-reconnect on wake, launch-at-login, Settings window, packaging polish

See [`PROTOCOL.md`](PROTOCOL.md) for the reverse-engineered protocol and
[`TESTING.md`](TESTING.md) for how to verify/extend it on hardware.

## Build & run

Requires macOS 14+. Builds with the Swift toolchain (full Xcode only needed for
the test target and notarized release).

The app needs a real `.app` bundle (with a Bluetooth usage string) for
CoreBluetooth permission — assemble and run it with:

```sh
./Packaging/make-app.sh debug
./.build/debug/Buddy.app/Contents/MacOS/Buddy
```

An earbuds icon appears in the menubar; click it for the panel. Run from
Terminal to watch the diagnostic log (`[BATTERY]`, `[RFCOMM]`, `[SEND]`, …).

Useful flags:

- `--channel N` — force a specific RFCOMM channel
- `--send AABB` — send a raw command (msgID `AA`, payload `BB`) after connect,
  for probing opcodes (repeatable)

## Layout

| Module          | Purpose                                                        |
| --------------- | -------------------------------------------------------------- |
| `Buddy`         | Executable: menubar app, BLE/BT coordination, diagnostics      |
| `BudsProtocol`  | Frame parser + encoder (CRC-16/XMODEM), status decode, commands |
| `BudsTransport` | RFCOMM control channel + connect monitor (IOBluetooth), BLE scan (CoreBluetooth) |
| `BudsCore`      | Domain model (`BudsDevice`, `ANCMode`, `EQPreset`)             |
| `BudsFeatures`  | ANC / EQ helpers                                               |
| `BudsUI`        | SwiftUI components: battery rings, ANC control, EQ, 3D model, HUD |

## License

GPL-3.0-or-later. Protocol framing/conventions follow
[ThePBone/GalaxyBudsClient](https://github.com/ThePBone/GalaxyBudsClient); the
Buds 3 FE battery offsets here were re-derived from our own captures.
