// swift-tools-version: 5.9
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
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.5.0")
        ),
        .package(
            url: "https://github.com/davidahouse/XCResultKit.git",
            .upToNextMajor(from: "1.2.2")
        )
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
//            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "XcresultparserTests",
            dependencies: ["XcresultparserLib"],
            resources: [
                .copy("TestAssets/test.xcresult"),
                .copy("TestAssets/test_merged.xcresult"),
                .copy("TestAssets/test_repeated.xcresult"),
                .copy("TestAssets/junit.xml"),
                .copy("TestAssets/junit_merged.xml"),
                .copy("TestAssets/junit_repeated.xml"),
                .copy("TestAssets/sonarTestExecution.xml"),
                .copy("TestAssets/cobertura.xml"),
                .copy("TestAssets/coberturaExcludingDirectory.xml"),
                .copy("TestAssets/warnings.json"),
                .copy("TestAssets/resultWithCompileError.xcresult"),
                .copy("TestAssets/sonarTestExecutionWithProjectRootAbsolute.xml"),
                .copy("TestAssets/sonarTestExecutionWithProjectRootRelative.xml")
            ]
        )
    ]
)
