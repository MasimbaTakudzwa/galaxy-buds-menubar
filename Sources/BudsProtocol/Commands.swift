import Foundation

/// Outbound command opcodes.
///
/// ⚠️ CANDIDATE VALUES — these are taken from GalaxyBudsClient's older models
/// (Buds2 / Pro) and have NOT been verified on Buds 3 FE hardware. The framing
/// + CRC around them is verified; the message IDs and payload encodings are the
/// unknowns to confirm. Use the `--send` CLI to probe the real opcodes, then
/// update these. They're `var` so they're trivial to retune.
public enum BudsOpcode {
  public static var noiseControl: UInt8 = 0x79   // payload: [mode]
  public static var equalizer: UInt8 = 0x86      // payload: [presetIndex]
}

public enum BudsCommand {
  /// Set noise-control mode. Wire value mapping is a candidate (see AppDelegate).
  public static func noiseControl(value: UInt8) -> [UInt8] {
    BudsMessageEncoder.encode(id: BudsOpcode.noiseControl, payload: [value])
  }

  /// Set equalizer preset by index.
  public static func equalizer(preset: UInt8) -> [UInt8] {
    BudsMessageEncoder.encode(id: BudsOpcode.equalizer, payload: [preset])
  }

  /// Arbitrary command — used by the `--send` probe harness.
  public static func raw(id: UInt8, payload: [UInt8]) -> [UInt8] {
    BudsMessageEncoder.encode(id: id, payload: payload)
  }
}
