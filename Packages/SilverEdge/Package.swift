// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SilverEdge",
    defaultLocalization: "en",
    platforms: [.macOS("15.0")],
    products: [
        // Everything the app is; started by the Xcode app target (SilverEdge.app).
        .library(name: "Shell", targets: ["Shell"]),
    ],
    targets: [
        // Samples as values and the pure logic over them. Foundation and Observation only
        // (scripts/check-modules.sh).
        .target(name: "Domain", path: "Sources/Domain"),
        // The kernel and process readers and the sampler. Only Shell imports it.
        .target(name: "Platform", dependencies: ["Domain"], path: "Sources/Platform"),
        // What the menu bar and panels draw with. Never Platform.
        .target(name: "UI", dependencies: ["Domain"], path: "Sources/UI", resources: [.process("Localization")]),
        // Composition: the app delegate, status items and panel windows.
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
