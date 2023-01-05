// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "Xcresultparser",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .executable(
            name: "xcresultparser",
            targets: ["CommandlineTool"]
        ),
        .library(
            name: "XcresultparserLib",
            targets: ["XcresultparserLib"]
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
            dependencies: ["XcresultparserLib"],
            path: "CommandlineTool"
        ),
        .target(
            name: "XcresultparserLib",
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
            dependencies: ["XcresultparserLib"],
            resources: [
                .copy("TestAssets/test.xcresult"),
                .copy("TestAssets/junit.xml"),
                .copy("TestAssets/sonarTestExecution.xml"),
                .copy("TestAssets/cobertura.xml"),
            ]
        )
    ]
)
