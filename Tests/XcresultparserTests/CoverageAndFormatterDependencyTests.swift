import Foundation
import Testing
@testable import XcresultparserLib

struct CoverageAndFormatterDependencyTests {
    @Test
    func testCoverageConverterMapsCoverageReportClientFailureToCouldNotLoadCoverageReport() async throws {
        var xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary(startTime: 1, finishTime: 2) }
        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        do {
            _ = try await CoverageConverter(
                with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
                strictPathnames: false,
                xcResultToolClient: xcresultClient,
                xcCovClient: xccovClient
            )
            Issue.record("Expected coverage report loading failure.")
        } catch let error as CoverageConverterError {
            #expect(error == .couldNotLoadCoverageReport)
        }
    }

    @Test
    func testCoverageConverterAcceptsNormalizedCoverageTargetFromProtocolClient() async throws {
        var xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in TestModelFactory.coverageReport(targetNames: ["App.framework", "Lib"]) }
        // The initialiser loads the line coverage along with the report.
        xccovClient.getCoverageDataHandler = { _ in try JSONDecoder().decode(FileCoverage.self, from: Data("{}".utf8)) }

        let converter = try await CoverageConverter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            coverageTargets: ["App"],
            strictPathnames: false,
            xcResultToolClient: xcresultClient,
            xcCovClient: xccovClient
        )

        #expect(converter.targetsInfo.contains("App.framework"))
    }

    // Catches listing targets running more than xccov's coverage report, e.g. loading the line coverage too.
    @Test
    func testTargetsInfoLoadsOnlyTheCoverageReport() async throws {
        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in TestModelFactory.coverageReport(targetNames: ["App.framework", "Lib"]) }

        let info = try await CoverageConverter.targetsInfo(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            xcCovClient: xccovClient
        )

        #expect(info == "\nApp.framework\nLib")
    }

    @Test
    func testTargetsInfoMapsCoverageReportClientFailureToCouldNotLoadCoverageReport() async {
        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        await #expect(throws: CoverageConverterError.couldNotLoadCoverageReport) {
            try await CoverageConverter.targetsInfo(
                with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
                xcCovClient: xccovClient
            )
        }
    }

    @Test
    func testCoverageConverterUnknownTargetErrorIncludesAvailableTargetsFromProtocolClient() async throws {
        var xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in TestModelFactory.coverageReport(targetNames: ["App.framework", "Lib"]) }

        do {
            _ = try await CoverageConverter(
                with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
                coverageTargets: ["Missing"],
                strictPathnames: false,
                xcResultToolClient: xcresultClient,
                xcCovClient: xccovClient
            )
            Issue.record("Expected unknown coverage target error.")
        } catch let error as CoverageConverterError {
            switch error {
            case let .unknownCoverageTargets(requested, available):
                #expect(requested == ["Missing"])
                #expect(Set(available) == Set(["App.framework", "Lib"]))
            case .couldNotLoadCoverageReport:
                Issue.record("Unexpected couldNotLoadCoverageReport.")
            case .notImplemented:
                Issue.record("Unexpected notImplemented case.")
            }
        }
    }

    // Catches the converter dropping the start time or line coverage it loads from the clients.
    @Test
    func testCoberturaConverterUsesTheInputsLoadedFromTheClients() async throws {
        var xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary(startTime: 42) }
        let report = CoverageReport(
            coveredLines: 1,
            executableLines: 1,
            lineCoverage: 1,
            targets: [
                CoverageTarget(
                    name: "App",
                    lineCoverage: 1,
                    executableLines: 1,
                    coveredLines: 1,
                    files: [
                        CoverageReportFile(
                            name: "Foo.swift",
                            path: "/tmp/Foo.swift",
                            lineCoverage: 1,
                            executableLines: 1,
                            coveredLines: 1,
                            functions: []
                        )
                    ]
                )
            ]
        )
        let lineCoverage = try JSONDecoder().decode(
            FileCoverage.self,
            from: Data(#"{"/tmp/Foo.swift": [{"isExecutable": true, "line": 1, "executionCount": 2}]}"#.utf8)
        )

        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in report }
        xccovClient.getCoverageDataHandler = { _ in lineCoverage }

        let converter = try await CoberturaCoverageConverter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            strictPathnames: false,
            xcResultToolClient: xcresultClient,
            xcCovClient: xccovClient
        )
        let xml = try converter.xmlString(quiet: true)

        #expect(xml.contains(#"timestamp="42.0""#))
        #expect(xml.contains(#"<line number="1" branch="false" hits="2"/>"#))
    }

    @Test
    func testFormatterCanInitializeWithoutCoverageReportIfNoCoverageFilterRequested() async throws {
        var xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        _ = try await XCResultFormatter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            formatter: TextResultFormatter(),
            coverageTargets: [],
            xcResultToolClient: xcresultClient,
            xcCovClient: xccovClient
        )
    }

    @Test
    func testFormatterFailsIfCoverageFilterRequestedAndCoverageReportUnavailable() async throws {
        var xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        await #expect(throws: CoverageConverterError.self) {
            try await XCResultFormatter(
                with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
                formatter: TextResultFormatter(),
                coverageTargets: ["App"],
                xcResultToolClient: xcresultClient,
                xcCovClient: xccovClient
            )
        }
    }

    @Test
    func testFormatterAcceptsNormalizedCoverageTargetFromProtocolClient() async throws {
        var xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in
            TestModelFactory.coverageReport(targetNames: ["App.framework"])
        }

        _ = try await XCResultFormatter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            formatter: TextResultFormatter(),
            coverageTargets: ["App"],
            xcResultToolClient: xcresultClient,
            xcCovClient: xccovClient
        )
    }

    // Catches the formatter starting xccov, which takes about 600 ms, when no coverage is shown.
    @Test(arguments: [
        (includesCoverage: false, coverageTargets: [String](), expectedReportLoads: 0),
        (includesCoverage: true, coverageTargets: [], expectedReportLoads: 1),
        // Requested targets are checked against the report even when coverage isn't shown.
        (includesCoverage: false, coverageTargets: ["App"], expectedReportLoads: 1)
    ])
    func testFormatterLoadsTheCoverageReportOnlyWhenNeeded(
        includesCoverage: Bool,
        coverageTargets: [String],
        expectedReportLoads: Int
    ) async throws {
        let reportLoads = CallCounter()
        var xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        var xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in
            await reportLoads.increment()
            return TestModelFactory.coverageReport(targetNames: ["App"])
        }

        _ = try await XCResultFormatter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            formatter: TextResultFormatter(),
            coverageTargets: coverageTargets,
            includesCoverage: includesCoverage,
            xcResultToolClient: xcresultClient,
            xcCovClient: xccovClient
        )

        #expect(await reportLoads.count == expectedReportLoads)
    }
}
