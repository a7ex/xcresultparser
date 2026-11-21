// swift-tools-version: 6.2
//
// Support policy:
// - Tools version: the Swift version shipped with the .0 release of the previous major Xcode,
//   so the package builds with the current Xcode and the one major version before it
//   (currently Xcode 27 and Xcode 26.0 → Swift 6.2).
// - Deployment target: two major macOS versions behind the current release, or the oldest
//   macOS that GitHub-hosted runners provide, whichever is newer
//   (currently macOS 27 → macOS 15, which is also the oldest GitHub-hosted runner).
// CI builds and tests on xcode-27 (macOS 27, newest Xcode), macos-26 (newest Xcode 26) and
// macos-15 (oldest supported Xcode).
import PackageDescription

// SwiftLint runs as a build tool plugin during local development only.
// On CI (GitHub Actions sets CI=true), `swift build --arch arm64 --arch x86_64` crashes with
// the plugin on Xcode 26.7, and linting isn't needed to build or test.
let lintOnBuild = Context.environment["CI"] == nil

let swiftLintDependencies: [Package.Dependency] = lintOnBuild ? [
    .package(
        url: "https://github.com/SimplyDanny/SwiftLintPlugins",
        from: "0.65.0"
    )
] : []

let swiftLintPlugins: [Target.PluginUsage] = lintOnBuild ? [
    .plugin(
        name: "SwiftLintBuildToolPlugin",
        package: "SwiftLintPlugins"
    )
] : []

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"), /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0335-existential-any.md
    .enableUpcomingFeature("InternalImportsByDefault"), /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0409-access-level-on-imports.md
    .enableUpcomingFeature("MemberImportVisibility"), /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    .enableUpcomingFeature("InferIsolatedConformances"), /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0470-isolated-conformances.md
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"), /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
    .enableUpcomingFeature("ImmutableWeakCaptures"), /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0481-weak-let.md
    .strictMemorySafety(), /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0458-strict-memory-safety.md
    .treatAllWarnings(as: .error) /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0480-swiftpm-warning-control.md
]

let package = Package(
    name: "Xcresultparser",
    platforms: [
        .macOS(.v15), // See the support policy at the top of this file.
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
            from: "1.8.0"
        )
    ] + swiftLintDependencies,
    targets: [
        .executableTarget(
            name: "CommandlineTool",
            dependencies: ["XcresultparserLib"],
            path: "CommandlineTool",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "XcresultparserLib",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ],
            path: "Sources",
            swiftSettings: swiftSettings,
            plugins: swiftLintPlugins
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
                .copy("TestAssets/sonarTestExecutionWithProjectRootRelative.xml"),
                .copy("TestAssets/parametrized.xcresult"),
                .copy("TestAssets/session_level_failure.xcresult"),
                .copy("TestAssets/junit_session_level_failure.xml"),
                .copy("TestAssets/Test-FlakyFixture.xcresult")
            ],
            swiftSettings: swiftSettings,
            plugins: swiftLintPlugins
        )
    ]
)
