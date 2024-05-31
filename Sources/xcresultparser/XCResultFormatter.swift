//
//  XCResultFormatter.swift
//  xcresultkitten
//
//  Created by Alex da Franca on 31.05.21.
//

import Foundation
import XCResultKit

public struct XCResultFormatter {
    private enum SummaryField: String {
        case errors, warnings, analyzerWarnings, tests, failed, skipped
    }
    
    private struct SummaryFields {
        let enabledFields: Set<SummaryField>
        init(specifiers: String) {
            enabledFields = Set(
                specifiers
                    .components(separatedBy: "|")
                    .compactMap { SummaryField(rawValue: $0) }
            )
        }
    }
    
    // MARK: - Properties
    
    private let resultFile: XCResultFile
    private let invocationRecord: ActionsInvocationRecord
    private let codeCoverage: CodeCoverage?
    private let outputFormatter: XCResultFormatting
    private let coverageTargets: Set<String>
    private let failedTestsOnly: Bool
    private let summaryFields: SummaryFields
    private let coverageReportFormat: CoverageReportFormat
    
    private var numFormatter: NumberFormatter = {
        let numFormatter = NumberFormatter()
        numFormatter.maximumFractionDigits = 4
        return numFormatter
    }()
    
    private var percentFormatter: NumberFormatter = {
        let numFormatter = NumberFormatter()
        numFormatter.maximumFractionDigits = 1
        return numFormatter
    }()
    
    // MARK: - Initializer
    
    public init?(
        with url: URL,
        formatter: XCResultFormatting,
        coverageTargets: [String] = [],
        failedTestsOnly: Bool = false,
        summaryFields: String = "errors|warnings|analyzerWarnings|tests|failed|skipped",
        coverageReportFormat: CoverageReportFormat = .methods
    ) {
        resultFile = XCResultFile(url: url)
        guard let record = resultFile.getInvocationRecord() else {
            return nil
        }
        invocationRecord = record
        outputFormatter = formatter
        codeCoverage = resultFile.getCodeCoverage()
        self.coverageTargets = codeCoverage?.targets(filteredBy: coverageTargets) ?? []
        self.failedTestsOnly = failedTestsOnly
        self.summaryFields = SummaryFields(specifiers: summaryFields)
        self.coverageReportFormat = coverageReportFormat
        
        // if let logsId = invocationRecord?.actions.last?.actionResult.logRef?.id {
        //    let testLogs = resultFile.getLogs(id: logsId)
        // }
        //
        //        let testSummary = resultFile.getActionTestSummary(id: "xxx")
        
        // let payload = resultFile.getPayload(id: "123")
        // let exportedPath = resultFile.exportPayload(id: "123")
    }
    
    // MARK: - Public API
    
    public var summary: String {
        if outputFormatter is MDResultFormatter {
            return createSummaryInOneLine()
        } else {
            return createSummary().joined(separator: "\n")
        }
    }
    
    public var testDetails: String {
        return createTestDetailsString().joined(separator: "\n")
    }
    
    public var divider: String {
        return outputFormatter.divider
    }
    
    public func documentPrefix(title: String) -> String {
        return outputFormatter.documentPrefix(title: title)
    }
    
    public var documentSuffix: String {
        return outputFormatter.documentSuffix
    }
    
    public var coverageDetails: String {
        return createCoverageReport().joined(separator: "\n")
    }
    
    // MARK: - Private API
    
    private func createSummary() -> [String] {
        let metrics = invocationRecord.metrics
        
        let analyzerWarningCount = metrics.analyzerWarningCount ?? 0
        let errorCount = metrics.errorCount ?? 0
        let testsCount = metrics.testsCount ?? 0
        let testsFailedCount = metrics.testsFailedCount ?? 0
        let warningCount = metrics.warningCount ?? 0
        let testsSkippedCount = metrics.testsSkippedCount ?? 0
        
        var lines = [String]()
        
        lines.append(
            outputFormatter.testConfiguration("Summary")
        )
        if summaryFields.enabledFields.contains(.errors) {
            lines.append(
                outputFormatter.resultSummaryLine("Number of errors = \(errorCount)", failed: errorCount != 0)
            )
        }
        if summaryFields.enabledFields.contains(.warnings) {
            lines.append(
                outputFormatter.resultSummaryLineWarning(
                    "Number of warnings = \(warningCount)",
                    hasWarnings: warningCount != 0
                )
            )
        }
        if summaryFields.enabledFields.contains(.analyzerWarnings) {
            lines.append(
                outputFormatter.resultSummaryLineWarning(
                    "Number of analyzer warnings = \(analyzerWarningCount)",
                    hasWarnings: analyzerWarningCount != 0
                )
            )
        }
        if summaryFields.enabledFields.contains(.tests) {
            lines.append(
                outputFormatter.resultSummaryLine("Number of tests = \(testsCount)", failed: false)
            )
        }
        if summaryFields.enabledFields.contains(.failed) {
            lines.append(
                outputFormatter.resultSummaryLine(
                    "Number of failed tests = \(testsFailedCount)",
                    failed: testsFailedCount != 0
                )
            )
        }
        if summaryFields.enabledFields.contains(.skipped) {
            lines.append(
                outputFormatter.resultSummaryLine(
                    "Number of skipped tests = \(testsSkippedCount)",
                    failed: testsSkippedCount != 0
                )
            )
        }
        return lines
    }
    
    private func createSummaryInOneLine() -> String {
        let metrics = invocationRecord.metrics
        
        let analyzerWarningCount = metrics.analyzerWarningCount ?? 0
        let errorCount = metrics.errorCount ?? 0
        let testsCount = metrics.testsCount ?? 0
        let testsFailedCount = metrics.testsFailedCount ?? 0
        let warningCount = metrics.warningCount ?? 0
        let testsSkippedCount = metrics.testsSkippedCount ?? 0
        
        var summary = ""
        if summaryFields.enabledFields.contains(.errors) {
            summary += "Errors: \(errorCount)"
        }
        if summaryFields.enabledFields.contains(.warnings) {
            summary += "; Warnings: \(warningCount)"
        }
        if summaryFields.enabledFields.contains(.analyzerWarnings) {
            summary += "; Analizer Warnings: \(analyzerWarningCount)"
        }
        if summaryFields.enabledFields.contains(.tests) {
            summary += "; Tests: \(testsCount)"
        }
        if summaryFields.enabledFields.contains(.failed) {
            summary += "; Failed: \(testsFailedCount)"
        }
        if summaryFields.enabledFields.contains(.skipped) {
            summary += "; Skipped: \(testsSkippedCount)"
        }
        return summary
    }
    
    private func createTestDetailsString() -> [String] {
        var lines = [String]()
        for testAction in invocationRecord.actions where testAction.schemeCommandName == "Test" {
            lines.append(contentsOf: createTestDetailsString(forAction: testAction))
        }
        return lines
    }
    
    private func createTestDetailsString(forAction testAction: ActionRecord) -> [String] {
        var lines = [String]()
        guard let testsId = testAction.actionResult.testsRef?.id,
              let testPlanRun = resultFile.getTestPlanRunSummaries(id: testsId) else {
            return lines
        }
        let testPlanRunSummaries = testPlanRun.summaries
        let failureSummaries = invocationRecord.issues.testFailureSummaries
        let runDestination = testAction.runDestination.displayName
        
        for thisSummary in testPlanRunSummaries {
            lines.append(
                outputFormatter.testConfiguration(thisSummary.name ?? "No-name")
            )
            for thisTestableSummary in thisSummary.testableSummaries {
                if let targetName = thisTestableSummary.targetName {
                    let targetConfig = "\(targetName) on '\(runDestination)'"
                    lines.append(
                        outputFormatter.testConfiguration(targetConfig)
                    )
                }
                
                if failedTestsOnly,
                   outputFormatter is CLIResultFormatter,
                   thisTestableSummary.tests.allSatisfy({ $0.hasNoFailedTests }) {
                    lines.append("No test failures")
                } else {
                    for thisTest in thisTestableSummary.tests {
                        lines += createTestSummaryInfo(thisTest, level: 0, failureSummaries: failureSummaries)
                    }
                }
                
                lines.append(
                    outputFormatter.divider
                )
            }
        }
        return lines
    }
    
    private func createTestSummaryInfo(
        _ group: ActionTestSummaryGroup,
        level: Int,
        failureSummaries: [TestFailureIssueSummary]
    ) -> [String] {
        var lines = [String]()
        if failedTestsOnly,
           !group.hasFailedTests {
            return lines
        }
        let header = "\(group.nameString) (\(numFormatter.unwrappedString(for: group.duration)))"
        
        switch level {
        case 0:
            break
        case 1:
            lines.append(
                outputFormatter.testTarget(header, failed: group.hasFailedTests)
            )
        case 2:
            lines.append(
                outputFormatter.testClass(header, failed: group.hasFailedTests)
            )
        default:
            lines.append(
                outputFormatter.testClass(header, failed: group.hasFailedTests)
            )
        }
        for subGroup in group.subtestGroups {
            lines += createTestSummaryInfo(subGroup, level: level + 1, failureSummaries: failureSummaries)
        }
        if !outputFormatter.accordionOpenTag.isEmpty {
            lines.append(
                outputFormatter.accordionOpenTag
            )
        }
        for thisTest in group.subtests {
            if !failedTestsOnly || thisTest.isFailed {
                lines.append(
                    actionTestFileStatusString(for: thisTest, failureSummaries: failureSummaries)
                )
            }
        }
        if !outputFormatter.accordionCloseTag.isEmpty {
            lines.append(
                outputFormatter.accordionCloseTag
            )
        }
        return lines
    }
    
    private func actionTestFileStatusString(
        for testData: ActionTestMetadata,
        failureSummaries: [TestFailureIssueSummary]
    ) -> String {
        let duration = numFormatter.unwrappedString(for: testData.duration)
        let icon = actionTestFileStatusStringIcon(testData: testData)
        let testTitle = "\(icon) \(testData.name ?? "Missing-Name") (\(duration))"
        let testCaseName = testData.identifier?.replacingOccurrences(of: "/", with: ".") ?? "No-identifier"
        if let summary = failureSummaries.first(where: { $0.testCaseName == testCaseName }) {
            return actionTestFailureStatusString(with: testTitle, and: summary)
        } else {
            return outputFormatter.singleTestItem(testTitle, failed: testData.isFailed)
        }
    }
    
    private func actionTestFileStatusStringIcon(testData: ActionTestMetadata) -> String {
        if testData.isSuccessful {
            return outputFormatter.testPassIcon
        }
        
        if testData.isSkipped {
            return outputFormatter.testSkipIcon
        }
        
        return outputFormatter.testFailIcon
    }
    
    private func actionTestFailureStatusString(
        with header: String,
        and failure: TestFailureIssueSummary
    ) -> String {
        return outputFormatter.failedTestItem(header, message: failure.message)
    }
    
    private func createCoverageReport() -> [String] {
        var lines = [String]()
        lines.append(
            outputFormatter.testConfiguration("Coverage report")
        )
        guard let codeCoverage = codeCoverage else {
            return lines
        }
        var executableLines = 0
        var coveredLines = 0
        for target in codeCoverage.targets {
            guard coverageTargets.contains(target.name) else { continue }
            let covPercent = percentFormatter.unwrappedString(for: target.lineCoverage * 100)
            executableLines += target.executableLines
            coveredLines += target.coveredLines
            if(coverageReportFormat != .totals) {
                lines.append(
                    outputFormatter.codeCoverageTargetSummary(
                        "\(target.name): \(covPercent)% (\(target.coveredLines)/\(target.executableLines))"
                    )
                )
                
                if(coverageReportFormat != .targets) {
                    if !outputFormatter.accordionOpenTag.isEmpty {
                        lines.append(
                            outputFormatter.accordionOpenTag
                        )
                    }
                    for file in target.files {
                        let covPercent = percentFormatter.unwrappedString(for: file.lineCoverage * 100)
                        lines.append(
                            outputFormatter.codeCoverageFileSummary(
                                "\(file.name): \(covPercent)% (\(file.coveredLines)/\(file.executableLines))"
                            )
                        )
                        if(coverageReportFormat != .classes) {
                            if !outputFormatter.accordionOpenTag.isEmpty {
                                lines.append(
                                    outputFormatter.accordionOpenTag
                                )
                            }
                            if !outputFormatter.tableOpenTag.isEmpty {
                                lines.append(
                                    outputFormatter.tableOpenTag
                                )
                            }
                            for function in file.functions {
                                let covPercentLine = percentFormatter.unwrappedString(for: function.lineCoverage * 100)
                                lines.append(
                                    outputFormatter.codeCoverageFunctionSummary(
                                        [
                                            "\(covPercentLine)%",
                                            "\(function.name):\(function.lineNumber)",
                                            "(\(function.coveredLines)/\(function.executableLines))",
                                            "\(function.executionCount) times"
                                        ]
                                    )
                                )
                            }
                            if !outputFormatter.tableCloseTag.isEmpty {
                                lines.append(
                                    outputFormatter.tableCloseTag
                                )
                            }
                            if !outputFormatter.accordionCloseTag.isEmpty {
                                lines.append(
                                    outputFormatter.accordionCloseTag
                                )
                            }
                        }
                    }
                    if !outputFormatter.accordionCloseTag.isEmpty {
                        lines.append(
                            outputFormatter.accordionCloseTag
                        )
                    }
                }
            }
        }
        // Append the total coverage below the header
        guard executableLines > 0 else { return lines }
        let fraction = Double(coveredLines) / Double(executableLines)
        let covPercent: String = percentFormatter.unwrappedString(for: fraction * 100)
        let line = outputFormatter.codeCoverageTargetSummary(
            "Total coverage: \(covPercent)% (\(coveredLines)/\(executableLines))")
        lines.insert(line, at: 1)
        return lines
    }
}

extension ActionTestMetadata {
    var isFailed: Bool {
        return isSuccessful == false && isSkipped == false
    }
    
    var isSuccessful: Bool {
        return testStatus == "Success" || testStatus == "Expected Failure"
    }
    
    var isSkipped: Bool {
        return testStatus == "Skipped"
    }
}

extension ActionTestSummaryGroup {
    var nameString: String {
        return name ?? "Unnamed"
    }
}

extension NumberFormatter {
    func unwrappedString(for input: Double?) -> String {
        return string(for: input) ?? ""
    }
}

extension CodeCoverage {
    func targets(filteredBy filter: [String]) -> Set<String> {
        let targetNames = targets.map { $0.name }
        guard !filter.isEmpty else {
            return Set(targetNames)
        }
        let filterSet = Set(filter)
        let filtered = targetNames.filter { thisTarget in
            // Clean up target.name. Split on '.' because the target.name is appended with .framework or .app
            guard let stripped = thisTarget.split(separator: ".").first else { return true }
            return filterSet.contains(String(stripped))
        }
        return Set(filtered)
    }
}

private extension ActionTestSummaryGroup {
    var hasFailedTests: Bool {
        for test in subtests {
            if test.isFailed {
                return true
            }
        }
        for subGroup in subtestGroups {
            if subGroup.hasFailedTests {
                return true
            }
        }
        return false
    }
    
    var hasNoFailedTests: Bool {
        return !hasFailedTests
    }
}
