// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "xcresultparser",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .executable(
            name: "xcresultparser",
            targets: ["CommandlineTool"]
        ),
        .library(
            name: "Xcresultparser",
            targets: ["Xcresultparser"]
        )
    ],
    dependencies: [
        .package(
            name: "swift-argument-parser",
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "0.4.3")
        ),
        .package(
            name: "XCResultKit",
            url: "https://github.com/davidahouse/XCResultKit.git",
            .upToNextMajor(from: "0.9.2")
        ),
    ],
    targets: [
        .executableTarget(
            name: "CommandlineTool",
            dependencies: ["Xcresultparser"],
            path: "CommandlineTool"
        ),
        .target(
            name: "Xcresultparser",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "XCResultKit",
                    package: "XCResultKit"
                ),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "XcresultparserTests",
            dependencies: ["Xcresultparser"],
            resources: [
                .copy("TestAssets/test.xcresult"),
            ]
        )
    ]
)
