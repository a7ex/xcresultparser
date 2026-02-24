import Foundation
@testable import XcresultparserLib
import Testing

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
