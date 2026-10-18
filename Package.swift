// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DualMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DualMac",
            targets: ["DualMac"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DualMac",
            dependencies: [],
            path: "Sources/DualMac"
        )
    ]
)
