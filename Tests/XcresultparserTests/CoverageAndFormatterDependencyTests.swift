import Foundation
import Testing
@testable import XcresultparserLib

struct CoverageAndFormatterDependencyTests {
    @Test
    func testCoverageConverterMapsCoverageReportClientFailureToCouldNotLoadCoverageReport() throws {
        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary(startTime: 1, finishTime: 2) }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        do {
            _ = try CoverageConverter(
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
    func testCoverageConverterAcceptsNormalizedCoverageTargetFromProtocolClient() throws {
        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in TestModelFactory.coverageReport(targetNames: ["App.framework", "Lib"]) }

        let converter = try CoverageConverter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            coverageTargets: ["App"],
            strictPathnames: false,
            xcResultToolClient: xcresultClient,
            xcCovClient: xccovClient
        )

        #expect(converter.targetsInfo.contains("App.framework"))
    }

    @Test
    func testCoverageConverterUnknownTargetErrorIncludesAvailableTargetsFromProtocolClient() throws {
        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in TestModelFactory.coverageReport(targetNames: ["App.framework", "Lib"]) }

        do {
            _ = try CoverageConverter(
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

    // Catches the converter ignoring prefetched inputs and running xccov or xcresulttool again.
    @Test
    func testCoberturaConverterUsesPrefetchedInputsInsteadOfRunningTheTools() throws {
        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary(startTime: 1) }
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

        let converter = try CoberturaCoverageConverter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            strictPathnames: false,
            xcResultToolClient: xcresultClient,
            xcCovClient: StubXCCovClient(),
            prefetchedInputs: PrefetchedCoverageInputs(report: report, startTime: 42, data: lineCoverage)
        )
        let xml = try converter.xmlString(quiet: true)

        #expect(xml.contains(#"timestamp="42.0""#))
        #expect(xml.contains(#"<line number="1" branch="false" hits="2"/>"#))
    }

    @Test
    func testFormatterCanInitializeWithoutCoverageReportIfNoCoverageFilterRequested() throws {
        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        _ = try XCResultFormatter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            formatter: TextResultFormatter(),
            coverageTargets: [],
            xcResultToolClient: xcresultClient,
            xcCovClient: xccovClient
        )
    }

    @Test
    func testFormatterFailsIfCoverageFilterRequestedAndCoverageReportUnavailable() throws {
        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        #expect(throws: CoverageConverterError.self) {
            try XCResultFormatter(
                with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
                formatter: TextResultFormatter(),
                coverageTargets: ["App"],
                xcResultToolClient: xcresultClient,
                xcCovClient: xccovClient
            )
        }
    }

    @Test
    func testFormatterAcceptsNormalizedCoverageTargetFromProtocolClient() throws {
        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in
            TestModelFactory.coverageReport(targetNames: ["App.framework"])
        }

        _ = try XCResultFormatter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            formatter: TextResultFormatter(),
            coverageTargets: ["App"],
            xcResultToolClient: xcresultClient,
            xcCovClient: xccovClient
        )
    }
}
