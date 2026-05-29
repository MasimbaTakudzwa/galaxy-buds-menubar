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
      dependencies: ["BudsCore", "BudsFeatures", "BudsUI"]
    ),
    .target(name: "BudsProtocol"),
    .target(name: "BudsTransport", dependencies: ["BudsProtocol"]),
    .target(name: "BudsCore", dependencies: ["BudsProtocol", "BudsTransport"]),
    .target(name: "BudsFeatures", dependencies: ["BudsCore"]),
    .target(name: "BudsUI", dependencies: ["BudsCore"], resources: [.copy("Resources")]),
    // Re-enable once full Xcode (not just Command Line Tools) is installed —
    // XCTest / Testing aren't bundled with CLT, so SwiftPM can't build tests.
    // .testTarget(name: "BudsProtocolTests", dependencies: ["BudsProtocol"]),
  ]
)
