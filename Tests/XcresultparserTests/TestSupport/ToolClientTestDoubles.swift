import Foundation
@testable import XcresultparserLib

enum TestDoubleError: Error {
    case forced
    case unimplemented
}

final class StubXCResultToolClient: XCResultToolProviding {
    var getBuildResultsHandler: (URL) throws -> XCBuildResults = { _ in throw TestDoubleError.unimplemented }
    var getTestSummaryHandler: (URL) throws -> XCSummary = { _ in throw TestDoubleError.unimplemented }
    var getTestsHandler: (URL) throws -> XCTests = { _ in throw TestDoubleError.unimplemented }
    var getTestDetailsHandler: (URL, String) throws -> XCTestDetails = { _, _ in throw TestDoubleError.unimplemented }
    var getActivitiesHandler: (URL, String) throws -> XCActivities = { _, _ in throw TestDoubleError.unimplemented }
    var getMetricsHandler: (URL, String) throws -> [XCTestWithMetrics] = { _, _ in throw TestDoubleError.unimplemented }

    func getBuildResults(path: URL) throws -> XCBuildResults {
        try getBuildResultsHandler(path)
    }

    func getTestSummary(path: URL) throws -> XCSummary {
        try getTestSummaryHandler(path)
    }

    func getTests(path: URL) throws -> XCTests {
        try getTestsHandler(path)
    }

    func getTestDetails(path: URL, testId: String) throws -> XCTestDetails {
        try getTestDetailsHandler(path, testId)
    }

    func getActivities(path: URL, testId: String) throws -> XCActivities {
        try getActivitiesHandler(path, testId)
    }

    func getMetrics(path: URL, testId: String) throws -> [XCTestWithMetrics] {
        try getMetricsHandler(path, testId)
    }
}

final class StubXCCovClient: XCCovProviding {
    var getCoverageDataHandler: (URL) throws -> FileCoverage = { _ in throw TestDoubleError.unimplemented }
    var getCoverageReportHandler: (URL) throws -> CoverageReport = { _ in throw TestDoubleError.unimplemented }
    var getCoverageForFileHandler: (URL, String) throws -> String = { _, _ in throw TestDoubleError.unimplemented }
    var getCoverageFileListHandler: (URL) throws -> [String] = { _ in throw TestDoubleError.unimplemented }

    func getCoverageData(path: URL) throws -> FileCoverage {
        try getCoverageDataHandler(path)
    }

    func getCoverageReport(path: URL) throws -> CoverageReport {
        try getCoverageReportHandler(path)
    }

    func getCoverageForFile(path: URL, filePath: String) throws -> String {
        try getCoverageForFileHandler(path, filePath)
    }

    func getCoverageFileList(path: URL) throws -> [String] {
        try getCoverageFileListHandler(path)
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
