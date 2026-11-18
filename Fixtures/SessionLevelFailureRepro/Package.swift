// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SessionLevelFailureRepro",
    platforms: [.macOS(.v14)],
    products: [.library(name: "SessionLevelFailureRepro", targets: ["SessionLevelFailureRepro"])],
    targets: [
        .target(name: "SessionLevelFailureRepro"),
        .testTarget(name: "SessionLevelFailureReproTests", dependencies: ["SessionLevelFailureRepro"])
    ]
)
