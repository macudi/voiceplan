// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "VoicePlan",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)
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
