import Foundation
@testable import XcresultparserLib
import Testing

@MainActor
struct CoverageAndFormatterDependencyTests {
    @Test
    func testCoverageConverterMapsCoverageReportClientFailureToCouldNotLoadCoverageReport() throws {
        let savedShellFactory = DependencyFactory.createShell
        let savedXCResultFactory = DependencyFactory.createXCResultToolClient
        let savedXCCovFactory = DependencyFactory.createXCCovClient
        defer {
            DependencyFactory.createShell = savedShellFactory
            DependencyFactory.createXCResultToolClient = savedXCResultFactory
            DependencyFactory.createXCCovClient = savedXCCovFactory
        }

        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary(startTime: 1, finishTime: 2) }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        DependencyFactory.createShell = { CapturingCommandline(response: Data()) }
        DependencyFactory.createXCResultToolClient = { _ in xcresultClient }
        DependencyFactory.createXCCovClient = { _ in xccovClient }

        do {
            _ = try CoverageConverter(
                with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
                strictPathnames: false
            )
            Issue.record("Expected coverage report loading failure.")
        } catch let error as CoverageConverterError {
            #expect(error == .couldNotLoadCoverageReport)
        }
    }

    @Test
    func testCoverageConverterAcceptsNormalizedCoverageTargetFromProtocolClient() throws {
        let savedShellFactory = DependencyFactory.createShell
        let savedXCResultFactory = DependencyFactory.createXCResultToolClient
        let savedXCCovFactory = DependencyFactory.createXCCovClient
        defer {
            DependencyFactory.createShell = savedShellFactory
            DependencyFactory.createXCResultToolClient = savedXCResultFactory
            DependencyFactory.createXCCovClient = savedXCCovFactory
        }

        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in TestModelFactory.coverageReport(targetNames: ["App.framework", "Lib"]) }

        DependencyFactory.createShell = { CapturingCommandline(response: Data()) }
        DependencyFactory.createXCResultToolClient = { _ in xcresultClient }
        DependencyFactory.createXCCovClient = { _ in xccovClient }

        let converter = try CoverageConverter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            coverageTargets: ["App"],
            strictPathnames: false
        )

        #expect(converter.targetsInfo.contains("App.framework"))
    }

    @Test
    func testCoverageConverterUnknownTargetErrorIncludesAvailableTargetsFromProtocolClient() throws {
        let savedShellFactory = DependencyFactory.createShell
        let savedXCResultFactory = DependencyFactory.createXCResultToolClient
        let savedXCCovFactory = DependencyFactory.createXCCovClient
        defer {
            DependencyFactory.createShell = savedShellFactory
            DependencyFactory.createXCResultToolClient = savedXCResultFactory
            DependencyFactory.createXCCovClient = savedXCCovFactory
        }

        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in TestModelFactory.coverageReport(targetNames: ["App.framework", "Lib"]) }

        DependencyFactory.createShell = { CapturingCommandline(response: Data()) }
        DependencyFactory.createXCResultToolClient = { _ in xcresultClient }
        DependencyFactory.createXCCovClient = { _ in xccovClient }

        do {
            _ = try CoverageConverter(
                with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
                coverageTargets: ["Missing"],
                strictPathnames: false
            )
            Issue.record("Expected unknown coverage target error.")
        } catch let error as CoverageConverterError {
            switch error {
            case let .unknownCoverageTargets(requested, available):
                #expect(requested == ["Missing"])
                #expect(Set(available) == Set(["App.framework", "Lib"]))
            case .couldNotLoadCoverageReport:
                Issue.record("Unexpected couldNotLoadCoverageReport.")
            }
        }
    }

    @Test
    func testFormatterCanInitializeWithoutCoverageReportIfNoCoverageFilterRequested() throws {
        let savedShellFactory = DependencyFactory.createShell
        let savedXCResultFactory = DependencyFactory.createXCResultToolClient
        let savedXCCovFactory = DependencyFactory.createXCCovClient
        defer {
            DependencyFactory.createShell = savedShellFactory
            DependencyFactory.createXCResultToolClient = savedXCResultFactory
            DependencyFactory.createXCCovClient = savedXCCovFactory
        }

        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        DependencyFactory.createShell = { CapturingCommandline(response: Data()) }
        DependencyFactory.createXCResultToolClient = { _ in xcresultClient }
        DependencyFactory.createXCCovClient = { _ in xccovClient }

        let formatter = XCResultFormatter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            formatter: TextResultFormatter(),
            coverageTargets: []
        )

        #expect(formatter != nil)
    }

    @Test
    func testFormatterFailsIfCoverageFilterRequestedAndCoverageReportUnavailable() throws {
        let savedShellFactory = DependencyFactory.createShell
        let savedXCResultFactory = DependencyFactory.createXCResultToolClient
        let savedXCCovFactory = DependencyFactory.createXCCovClient
        defer {
            DependencyFactory.createShell = savedShellFactory
            DependencyFactory.createXCResultToolClient = savedXCResultFactory
            DependencyFactory.createXCCovClient = savedXCCovFactory
        }

        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in throw TestDoubleError.forced }

        DependencyFactory.createShell = { CapturingCommandline(response: Data()) }
        DependencyFactory.createXCResultToolClient = { _ in xcresultClient }
        DependencyFactory.createXCCovClient = { _ in xccovClient }

        let formatter = XCResultFormatter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            formatter: TextResultFormatter(),
            coverageTargets: ["App"]
        )

        #expect(formatter == nil)
    }

    @Test
    func testFormatterAcceptsNormalizedCoverageTargetFromProtocolClient() throws {
        let savedShellFactory = DependencyFactory.createShell
        let savedXCResultFactory = DependencyFactory.createXCResultToolClient
        let savedXCCovFactory = DependencyFactory.createXCCovClient
        defer {
            DependencyFactory.createShell = savedShellFactory
            DependencyFactory.createXCResultToolClient = savedXCResultFactory
            DependencyFactory.createXCCovClient = savedXCCovFactory
        }

        let xcresultClient = StubXCResultToolClient()
        xcresultClient.getBuildResultsHandler = { _ in try TestModelFactory.buildResults() }
        xcresultClient.getTestSummaryHandler = { _ in try TestModelFactory.summary() }
        xcresultClient.getTestsHandler = { _ in try TestModelFactory.tests() }
        let xccovClient = StubXCCovClient()
        xccovClient.getCoverageReportHandler = { _ in
            TestModelFactory.coverageReport(targetNames: ["App.framework"])
        }

        DependencyFactory.createShell = { CapturingCommandline(response: Data()) }
        DependencyFactory.createXCResultToolClient = { _ in xcresultClient }
        DependencyFactory.createXCCovClient = { _ in xccovClient }

        let formatter = XCResultFormatter(
            with: URL(fileURLWithPath: "/tmp/fake.xcresult"),
            formatter: TextResultFormatter(),
            coverageTargets: ["App"]
        )

        #expect(formatter != nil)
    }
}
