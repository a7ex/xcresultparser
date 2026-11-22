import Foundation
@testable import XcresultparserLib

enum TestDoubleError: Error {
    case forced
    case unimplemented
}

struct StubXCResultToolClient: XCResultToolProviding {
    var getBuildResultsHandler: @Sendable (URL) async throws -> XCBuildResults = { _ in throw TestDoubleError.unimplemented }
    var getTestSummaryHandler: @Sendable (URL) async throws -> XCSummary = { _ in throw TestDoubleError.unimplemented }
    var getTestsHandler: @Sendable (URL) async throws -> XCTests = { _ in throw TestDoubleError.unimplemented }
    var getTestDetailsHandler: @Sendable (URL, String) async throws -> XCTestDetails = { _, _ in
        throw TestDoubleError.unimplemented
    }
    var getActivitiesHandler: @Sendable (URL, String) async throws -> XCActivities = { _, _ in
        throw TestDoubleError.unimplemented
    }
    var getMetricsHandler: @Sendable (URL, String) async throws -> [XCTestWithMetrics] = { _, _ in
        throw TestDoubleError.unimplemented
    }

    func getBuildResults(path: URL) async throws -> XCBuildResults {
        try await getBuildResultsHandler(path)
    }

    func getTestSummary(path: URL) async throws -> XCSummary {
        try await getTestSummaryHandler(path)
    }

    func getTests(path: URL) async throws -> XCTests {
        try await getTestsHandler(path)
    }

    func getTestDetails(path: URL, testId: String) async throws -> XCTestDetails {
        try await getTestDetailsHandler(path, testId)
    }

    func getActivities(path: URL, testId: String) async throws -> XCActivities {
        try await getActivitiesHandler(path, testId)
    }

    func getMetrics(path: URL, testId: String) async throws -> [XCTestWithMetrics] {
        try await getMetricsHandler(path, testId)
    }
}

struct StubXCCovClient: XCCovProviding {
    var getCoverageDataHandler: @Sendable (URL) async throws -> FileCoverage = { _ in throw TestDoubleError.unimplemented }
    var getCoverageReportHandler: @Sendable (URL) async throws -> CoverageReport = { _ in throw TestDoubleError.unimplemented }
    var getCoverageForFileHandler: @Sendable (URL, String) async throws -> String = { _, _ in
        throw TestDoubleError.unimplemented
    }
    var getCoverageFileListHandler: @Sendable (URL) async throws -> [String] = { _ in throw TestDoubleError.unimplemented }

    func getCoverageData(path: URL) async throws -> FileCoverage {
        try await getCoverageDataHandler(path)
    }

    func getCoverageReport(path: URL) async throws -> CoverageReport {
        try await getCoverageReportHandler(path)
    }

    func getCoverageForFile(path: URL, filePath: String) async throws -> String {
        try await getCoverageForFileHandler(path, filePath)
    }

    func getCoverageFileList(path: URL) async throws -> [String] {
        try await getCoverageFileListHandler(path)
    }
}

enum TestModelFactory {
    static func buildResults(warningCount: Int = 0) throws -> XCBuildResults {
        let json = """
        {
          "analyzerWarningCount": 0,
          "analyzerWarnings": [],
          "destination": {
            "deviceId": "device-1",
            "deviceName": "My Mac"
          },
          "endTime": 2.0,
          "errorCount": 0,
          "errors": [],
          "startTime": 1.0,
          "warningCount": \(warningCount),
          "warnings": []
        }
        """
        return try JSONDecoder().decode(XCBuildResults.self, from: Data(json.utf8))
    }

    static func summary(startTime: Double? = nil, finishTime: Double? = nil) throws -> XCSummary {
        let startFragment = startTime.map { "\"startTime\": \($0)," } ?? ""
        let finishFragment = finishTime.map { "\"finishTime\": \($0)," } ?? ""
        let json = """
        {
          "title": "Test",
          "environmentDescription": "Env",
          "topInsights": [],
          "result": "Passed",
          "totalTestCount": 0,
          "passedTests": 0,
          "failedTests": 0,
          "skippedTests": 0,
          "expectedFailures": 0,
          "statistics": [],
          "devicesAndConfigurations": [],
          "testFailures": [],
          \(startFragment)
          \(finishFragment)
          "placeholder": true
        }
        """
        return try JSONDecoder().decode(XCSummary.self, from: Data(json.utf8))
    }

    static func tests() throws -> XCTests {
        let json = """
        {
          "testPlanConfigurations": [],
          "devices": [],
          "testNodes": []
        }
        """
        return try JSONDecoder().decode(XCTests.self, from: Data(json.utf8))
    }

    static func coverageReport(targetNames: [String]) -> CoverageReport {
        CoverageReport(
            coveredLines: 0,
            executableLines: 0,
            lineCoverage: 0,
            targets: targetNames.map { name in
                CoverageTarget(
                    name: name,
                    lineCoverage: 0,
                    executableLines: 0,
                    coveredLines: 0,
                    files: []
                )
            }
        )
    }
}
