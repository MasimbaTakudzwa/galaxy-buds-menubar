// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "Buddy",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "Buddy", targets: ["Buddy"]),
    .library(name: "BudsProtocol", targets: ["BudsProtocol"]),
    .library(name: "BudsTransport", targets: ["BudsTransport"]),
    .library(name: "BudsCore", targets: ["BudsCore"]),
    .library(name: "BudsFeatures", targets: ["BudsFeatures"]),
    .library(name: "BudsUI", targets: ["BudsUI"]),
  ],
  targets: [
    .executableTarget(
      name: "Buddy",
      dependencies: ["BudsProtocol", "BudsTransport", "BudsCore", "BudsFeatures", "BudsUI"]
    ),
    .target(name: "BudsProtocol"),
    .target(name: "BudsTransport", dependencies: ["BudsProtocol"]),
    .target(name: "BudsCore", dependencies: ["BudsProtocol", "BudsTransport"]),
    .target(name: "BudsFeatures", dependencies: ["BudsCore"]),
    .target(name: "BudsUI", dependencies: ["BudsProtocol", "BudsCore"], resources: [.copy("Resources")]),
    // Uses Swift Testing — runs under full Xcode (e.g. CI). Command Line Tools
    // alone don't bundle the Testing module, so `swift test` is a no-op locally,
    // but `swift build` is unaffected (test targets aren't built by it).
    .testTarget(name: "BudsProtocolTests", dependencies: ["BudsProtocol"]),
  ]
)
