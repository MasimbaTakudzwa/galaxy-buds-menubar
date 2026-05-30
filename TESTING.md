# Testing checklist — verify from terminal

Run the app from Terminal so you see the diagnostic log:

```sh
cd ~/DevProjects/Buddy
./Packaging/make-app.sh debug          # rebuild after any code change
./.build/debug/Buddy.app/Contents/MacOS/Buddy
```

Quit with Ctrl-C.

---

## 1. Things that should already work (confirm)

| Check | Expected log / behaviour |
|---|---|
| Build identity | `=== Buddy 0.1 … (build send-path-11) ===` |
| Encoder | `[SELFTEST] encoder = PASS` |
| Manager channel | `[RFCOMM] opening channel 27…` → `open complete: status=0` |
| Live battery | `[BATTERY] left=NN right=NN case=NN` matches your phone |
| Menubar panel | L/R/case rings match reality |
| Connect HUD | pops when you take buds out of the case / reconnect |

If all six hold, the read path is solid.

---

## 2. Find the ANC-mode byte (passive, safe)

We don't yet know which byte in the status frame encodes the noise mode.
Find it by changing the mode on your **phone** and diffing the frames:

1. Put the buds in your ears, run Buddy.
2. On Galaxy Wearable, set **Off**, wait 2s. Copy the `[MSG] id=0x61 payload=` line.
3. Set **Ambient**, wait 2s. Copy the line.
4. Set **ANC**, wait 2s. Copy the line.
5. Set **Adaptive** (if present), copy the line.

Paste the four `payload=` lines labelled with the mode. The byte that changes
`off→ambient→anc` (likely values like `0 / 2 / 1`) is the ANC offset. Also watch
for any `[MSG?] id=0x..` lines that appear *only* when the mode changes — that
could be a dedicated noise-control message.

Once known, I'll add it to `BudsStatusDecoder` so the segmented control
reflects the real mode, and confirm the value mapping.

---

## 3. Find the ANC *send* opcode (active probe)

The phone sends ANC commands over its own connection, so we can't sniff them —
we brute-force candidates over our channel and watch the status byte / your ears.

The app currently sends opcode **`0x79`** when you click the ANC control. Try it
first: click **ANC** in the panel and see if the noise mode actually changes.

If nothing happens, probe candidates from the CLI (each sends one frame ~0.6s
after the channel opens; `7900` = msgID 0x79, payload 0x00):

```sh
# try msgID 0x79 with payload off/anc/ambient
./.build/debug/Buddy.app/Contents/MacOS/Buddy --send 7900
./.build/debug/Buddy.app/Contents/MacOS/Buddy --send 7901
./.build/debug/Buddy.app/Contents/MacOS/Buddy --send 7902

# other candidate message IDs to sweep (payload 0x01):
./.build/debug/Buddy.app/Contents/MacOS/Buddy --send 7801
./.build/debug/Buddy.app/Contents/MacOS/Buddy --send 9801
./.build/debug/Buddy.app/Contents/MacOS/Buddy --send 9a01
```

After each, note: did the noise mode audibly change, and did a `[MSG] id=0x61`
with a changed ANC byte appear? The combo of (msgID, payload) that flips the
mode is the real command. Report the winners and I'll wire them in + update
`BudsOpcode`.

> Safe to experiment: worst case the buds ignore an unknown command. They
> validate CRC (which is correct), so a wrong opcode is simply a no-op.

---

## 4. Find the EQ opcode (same method)

Click EQ presets in the panel (sends opcode `0x86`, payload = preset index).
If presets don't change, sweep:

```sh
./.build/debug/Buddy.app/Contents/MacOS/Buddy --send 8601   # preset 1
./.build/debug/Buddy.app/Contents/MacOS/Buddy --send 8600   # normal
```

Report whether the EQ audibly changes / a status frame reflects it.

---

## 5. What to send me when you're back

- The four labelled `0x61 payload=` lines from step 2
- Any `--send` (msgID, payload) combos that changed ANC or EQ in step 3/4
- Anything that behaved unexpectedly

With those, I can lock the ANC/EQ decode + send, and the segmented control and
EQ row become fully functional two-way controls.
