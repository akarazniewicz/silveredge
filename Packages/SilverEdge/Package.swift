// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SilverEdge",
    defaultLocalization: "en",
    platforms: [.macOS("15.0")],
    products: [
        .library(name: "Shell", targets: ["Shell"]),
    ],
    targets: [
        .target(name: "Domain", path: "Sources/Domain"),
        .target(name: "Platform", dependencies: ["Domain"], path: "Sources/Platform"),
        .target(name: "UI", dependencies: ["Domain"], path: "Sources/UI", resources: [.process("Localization")]),
        .target(
            name: "Shell",
            dependencies: ["Domain", "Platform", "UI"],
            path: "Sources/Shell",
            resources: [.process("Localization")]
        ),
        .testTarget(
            name: "SilverEdgeTests",
            dependencies: ["Domain", "Platform", "UI", "Shell"],
            path: "Tests/SilverEdgeTests"
        )
    ]
)
