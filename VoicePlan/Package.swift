// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VoicePlan",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "VoicePlan", targets: ["VoicePlan"])
    ],
    targets: [
        .target(
            name: "VoicePlan",
            path: "Sources"
        )
    ]
)
