# Galaxy Buds 3 FE protocol notes

Reverse-engineered from live captures on a Galaxy Buds 3 FE paired to macOS.
Status: ✅ verified on hardware · 🟡 candidate (unverified) · ⬜ unknown.

## Transport

- **Detection (BLE):** Samsung manufacturer advertisement, company ID `0x0075`.
  The base payload (~26 B) is static/encrypted; opening the case appends a
  ~13 B discoverable block (payload grows past ~30 B). We use the *length jump*
  as a lid-open signal, not the contents (the contents are encrypted). ✅
- **Control (Classic BT / RFCOMM):** the `GEARMANAGER` SDP service,
  UUID `2e73a4ad-332d-41fc-90e2-16bef06523f2`, RFCOMM channel 27. ✅
  (Match by UUID — the SDP *name* field is sometimes empty.)

## Frame format ✅

```
FD | length(2, little-endian) | msgID(1) | payload(N) | CRC16(2, LE) | DD
```

- `length = 1 (msgID) + N (payload) + 2 (CRC)`, stored in the **low 10 bits**
  of the 2-byte header (`header & 0x03FF`); upper bits are flags on *received*
  frames (response/fragment) — we send them as 0.
- **CRC-16/XMODEM** (poly `0x1021`, init `0x0000`, no reflection), over
  `msgID + payload`, stored little-endian. Verified: re-encoding a captured
  frame reproduces it byte-for-byte.
- RFCOMM reads don't align to frames — one read may hold several frames or a
  partial one — so the parser buffers and resyncs on `FD`.

## Messages

| msgID | Name | Notes | Status |
|---|---|---|---|
| `0x60` | STATUS_UPDATED | `p[1]=left p[2]=right p[5]=placement p[6]=case` | ✅ |
| `0x61` | EXTENDED_STATUS_UPDATED | `p[2]=left p[3]=right p[4]=coupled p[5]=primary p[6]=placement p[7]=case` | ✅ |
| `0x68` | software/version info | ASCII version strings in payload | 🟡 |
| `0xf2`/`0xf4`/`0xf5` | debug-log stream | large, high-frequency; ignored | — |
| `0x79` | SET_NOISE_CONTROL | send `[mode]` — opcode + mapping unverified | 🟡 |
| `0x86` | SET_EQUALIZER | send `[presetIndex]` — unverified | 🟡 |
| — | noise-mode in status | which byte encodes Off/Ambient/ANC/Adaptive | ⬜ |

Battery byte = 0 means "not reported" (e.g. case while buds are out).

## Candidate wire mappings (unverified)

- ANC mode → value: `off=0, anc=1, ambient=2, adaptive=3`
- EQ preset → index: `normal=0, bassBoost=1, soft=2, dynamic=3, clear=4, treble=5`

See `TESTING.md` for how to confirm these on hardware.

## Credit

Framing and the message-ID conventions follow
[ThePBone/GalaxyBudsClient](https://github.com/ThePBone/GalaxyBudsClient)
(the reference Galaxy Buds protocol implementation). Battery offsets and the
Buds 3 FE specifics here were re-derived from our own captures.
