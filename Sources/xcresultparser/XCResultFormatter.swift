//
//  XCResultFormatter.swift
//  xcresultkitten
//
//  Created by Alex da Franca on 31.05.21.
//

import Foundation

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

    private struct FormattedTestGroup {
        let name: String
        let duration: Double
        let subtests: [FormattedTest]
        let subtestGroups: [FormattedTestGroup]

        var hasFailedTests: Bool {
            if subtests.contains(where: \.isFailed) {
                return true
            }
            if subtestGroups.contains(where: \.hasFailedTests) {
                return true
            }
            return false
        }

        var hasNoFailedTests: Bool {
            !hasFailedTests
        }
    }

    private struct FormattedTest {
        let identifier: String
        let name: String
        let duration: Double?
        let isFailed: Bool
        let isSkipped: Bool

        var isSuccessful: Bool {
            !isFailed && !isSkipped
        }
    }

    // MARK: - Properties

    private let outputFormatter: XCResultFormatting
    private let coverageReport: CoverageReport?
    private let buildResults: XCBuildResults
    private let testSummary: XCSummary
    private let tests: XCTests
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
        let client = XCResultToolClient()
        guard let buildResults = try? client.getBuildResults(path: url),
              let summary = try? client.getTestSummary(path: url),
              let tests = try? client.getTests(path: url) else {
            return nil
        }

        self.buildResults = buildResults
        self.testSummary = summary
        self.tests = tests
        outputFormatter = formatter
        self.coverageReport = try? Self.getCoverageReportAsJSON(resultFileURL: url, shell: DependencyFactory.createShell())
        self.coverageTargets = Self.targets(filteredBy: coverageTargets, availableTargets: coverageReport?.targets.map(\.name) ?? [])
        self.failedTestsOnly = failedTestsOnly
        self.summaryFields = SummaryFields(specifiers: summaryFields)
        self.coverageReportFormat = coverageReportFormat
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
        let analyzerWarningCount = buildResults.analyzerWarningCount
        let errorCount = buildResults.errorCount
        let testsCount = testSummary.totalTestCount
        let testsFailedCount = testSummary.failedTests
        let warningCount = buildResults.warningCount
        let testsSkippedCount = testSummary.skippedTests

        var lines = [String]()

        lines.append(outputFormatter.testConfiguration("Summary"))
        if summaryFields.enabledFields.contains(.errors) {
            lines.append(outputFormatter.resultSummaryLine("Number of errors = \(errorCount)", failed: errorCount != 0))
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
            lines.append(outputFormatter.resultSummaryLine("Number of tests = \(testsCount)", failed: false))
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
        let analyzerWarningCount = buildResults.analyzerWarningCount
        let errorCount = buildResults.errorCount
        let testsCount = testSummary.totalTestCount
        let testsFailedCount = testSummary.failedTests
        let warningCount = buildResults.warningCount
        let testsSkippedCount = testSummary.skippedTests

        var summary = ""
        if summaryFields.enabledFields.contains(.errors) {
            summary += "Errors: \(errorCount)"
        }
        if summaryFields.enabledFields.contains(.warnings) {
            summary += "; Warnings: \(warningCount)"
        }
        if summaryFields.enabledFields.contains(.analyzerWarnings) {
            summary += "; Analyzer Warnings: \(analyzerWarningCount)"
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
        let runDestination = tests.devices.first?.deviceName ?? "Unknown destination"

        let configuredNodes = tests.testPlanConfigurations.map { config in
            (
                name: config.configurationName,
                nodes: nodes(for: config, in: tests.testNodes)
            )
        }

        let entries: [(name: String, nodes: [XCTestNode])] = if configuredNodes.isEmpty {
            [(testSummary.title, tests.testNodes)]
        } else {
            configuredNodes
        }

        for entry in entries {
            lines.append(outputFormatter.testConfiguration(entry.name))

            let groups = entry.nodes.compactMap { mapGroup(node: $0, currentTestClassName: nil) }
            let targetLabel = targetName(for: groups)
            if let targetLabel {
                lines.append(outputFormatter.testConfiguration("\(targetLabel) on '\(runDestination)'"))
            }

            if failedTestsOnly,
               outputFormatter is CLIResultFormatter,
               groups.allSatisfy(\.hasNoFailedTests) {
                lines.append("No test failures")
            } else {
                for group in groups {
                    lines += createTestSummaryInfo(group, level: 0, failureSummaries: testSummary.testFailures)
                }
            }

            lines.append(outputFormatter.divider)
        }

        return lines
    }

    private func targetName(for groups: [FormattedTestGroup]) -> String? {
        if let bundle = groups.first(where: { $0.name.hasSuffix(".xctest") }) {
            return bundle.name.replacingOccurrences(of: ".xctest", with: "")
        }
        return groups.first?.name
    }

    private func createTestSummaryInfo(
        _ group: FormattedTestGroup,
        level: Int,
        failureSummaries: [XCTestFailure]
    ) -> [String] {
        var lines = [String]()
        if failedTestsOnly,
           !group.hasFailedTests {
            return lines
        }
        let header = "\(group.name) (\(numFormatter.unwrappedString(for: group.duration)))"

        switch level {
        case 0:
            break
        case 1:
            lines.append(outputFormatter.testTarget(header, failed: group.hasFailedTests))
        case 2:
            lines.append(outputFormatter.testClass(header, failed: group.hasFailedTests))
        default:
            lines.append(outputFormatter.testClass(header, failed: group.hasFailedTests))
        }
        for subGroup in group.subtestGroups {
            lines += createTestSummaryInfo(subGroup, level: level + 1, failureSummaries: failureSummaries)
        }
        if !outputFormatter.accordionOpenTag.isEmpty {
            lines.append(outputFormatter.accordionOpenTag)
        }
        for thisTest in group.subtests {
            if !failedTestsOnly || thisTest.isFailed {
                lines.append(actionTestFileStatusString(for: thisTest, failureSummaries: failureSummaries))
            }
        }
        if !outputFormatter.accordionCloseTag.isEmpty {
            lines.append(outputFormatter.accordionCloseTag)
        }
        return lines
    }

    private func actionTestFileStatusString(
        for testData: FormattedTest,
        failureSummaries: [XCTestFailure]
    ) -> String {
        let duration = numFormatter.unwrappedString(for: testData.duration)
        let icon = actionTestFileStatusStringIcon(testData: testData)
        let testTitle = "\(icon) \(testData.name) (\(duration))"
        let testCaseName = testData.identifier.replacingOccurrences(of: "/", with: ".")
        if let summary = failureSummaries.first(where: { $0.testIdentifierString == testCaseName }) {
            return actionTestFailureStatusString(with: testTitle, and: summary)
        }
        return outputFormatter.singleTestItem(testTitle, failed: testData.isFailed)
    }

    private func actionTestFileStatusStringIcon(testData: FormattedTest) -> String {
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
        and failure: XCTestFailure
    ) -> String {
        return outputFormatter.failedTestItem(header, message: failure.failureText)
    }

    private func createCoverageReport() -> [String] {
        var lines = [String]()
        lines.append(outputFormatter.testConfiguration("Coverage report"))
        guard let coverageReport else {
            return lines
        }

        var executableLines = 0
        var coveredLines = 0
        for target in coverageReport.targets {
            let targetData = createCoverageReportFor(target: target)
            lines += targetData.lines
            executableLines += targetData.executableLines
            coveredLines += targetData.coveredLines
        }

        guard executableLines > 0 else { return lines }
        let fraction = Double(coveredLines) / Double(executableLines)
        let covPercent = percentFormatter.unwrappedString(for: fraction * 100)
        let line = outputFormatter.codeCoverageTargetSummary("Total coverage: \(covPercent)% (\(coveredLines)/\(executableLines))")
        lines.insert(line, at: 1)
        return lines
    }

    private func createCoverageReportFor(target: CoverageTarget) -> CodeCoverageParseResult {
        var lines = [String]()
        var executableLines = 0
        var coveredLines = 0
        guard coverageTargets.contains(target.name) else {
            return CodeCoverageParseResult(lines: lines, executableLines: executableLines, coveredLines: coveredLines)
        }

        let covPercent = percentFormatter.unwrappedString(for: target.lineCoverage * 100)
        executableLines += target.executableLines
        coveredLines += target.coveredLines
        guard coverageReportFormat != .totals else {
            return CodeCoverageParseResult(lines: lines, executableLines: executableLines, coveredLines: coveredLines)
        }

        lines.append(
            outputFormatter.codeCoverageTargetSummary(
                "\(target.name): \(covPercent)% (\(target.coveredLines)/\(target.executableLines))"
            )
        )

        if coverageReportFormat != .targets {
            if !outputFormatter.accordionOpenTag.isEmpty {
                lines.append(outputFormatter.accordionOpenTag)
            }
            for file in target.files {
                lines += createCoverageReportFor(file: file)
            }
            if !outputFormatter.accordionCloseTag.isEmpty {
                lines.append(outputFormatter.accordionCloseTag)
            }
        }
        return CodeCoverageParseResult(lines: lines, executableLines: executableLines, coveredLines: coveredLines)
    }

    private func createCoverageReportFor(file: CoverageReportFile) -> [String] {
        var lines = [String]()
        let covPercent = percentFormatter.unwrappedString(for: file.lineCoverage * 100)
        lines.append(
            outputFormatter.codeCoverageFileSummary(
                "\(file.name): \(covPercent)% (\(file.coveredLines)/\(file.executableLines))"
            )
        )
        if coverageReportFormat != .classes {
            if !outputFormatter.accordionOpenTag.isEmpty {
                lines.append(outputFormatter.accordionOpenTag)
            }
            if !outputFormatter.tableOpenTag.isEmpty {
                lines.append(outputFormatter.tableOpenTag)
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
                lines.append(outputFormatter.tableCloseTag)
            }
            if !outputFormatter.accordionCloseTag.isEmpty {
                lines.append(outputFormatter.accordionCloseTag)
            }
        }
        return lines
    }

    private func nodes(for configuration: XCConfiguration, in roots: [XCTestNode]) -> [XCTestNode] {
        var matches = [XCTestNode]()
        for root in roots {
            matches.append(contentsOf: findConfigurationChildren(in: root, configuration: configuration))
        }
        return matches.isEmpty ? roots : matches
    }

    private func findConfigurationChildren(in node: XCTestNode, configuration: XCConfiguration) -> [XCTestNode] {
        if node.nodeType == .testPlanConfiguration &&
            (node.name == configuration.configurationName || node.nodeIdentifier == configuration.configurationId) {
            return node.children ?? []
        }

        return (node.children ?? []).flatMap { findConfigurationChildren(in: $0, configuration: configuration) }
    }

    private func mapGroup(node: XCTestNode, currentTestClassName: String?) -> FormattedTestGroup? {
        guard node.nodeType != .testCase else {
            return nil
        }

        let groupName = mappedGroupName(for: node)
        let nextTestClassName: String? = if node.nodeType == .testSuite {
            groupName
        } else {
            currentTestClassName
        }

        let children = node.children ?? []
        let tests = children
            .filter { $0.nodeType == .testCase }
            .map { mapTest(node: $0, testClassName: nextTestClassName) }

        let groups = children.compactMap { child in
            mapGroup(node: child, currentTestClassName: nextTestClassName)
        }

        let duration = node.durationInSeconds ?? tests.compactMap(\.duration).reduce(0, +) + groups.reduce(0) { $0 + $1.duration }

        return FormattedTestGroup(
            name: groupName,
            duration: duration,
            subtests: tests,
            subtestGroups: groups
        )
    }

    private func mapTest(node: XCTestNode, testClassName: String?) -> FormattedTest {
        let result = node.result ?? .unknown
        let identifier: String
        if let testClassName {
            identifier = "\(testClassName)/\(node.name)"
        } else {
            identifier = node.name
        }
        return FormattedTest(
            identifier: identifier,
            name: node.name,
            duration: node.durationInSeconds,
            isFailed: result == .failed,
            isSkipped: result == .skipped || result == .expectedFailure
        )
    }

    private func mappedGroupName(for node: XCTestNode) -> String {
        switch node.nodeType {
        case .unitTestBundle, .uiTestBundle:
            return node.name.hasSuffix(".xctest") ? node.name : "\(node.name).xctest"
        default:
            return node.name
        }
    }

    private static func targets(filteredBy filter: [String], availableTargets: [String]) -> Set<String> {
        guard !filter.isEmpty else {
            return Set(availableTargets)
        }
        let filterSet = Set(filter)
        let filtered = availableTargets.filter { thisTarget in
            guard let stripped = thisTarget.split(separator: ".").first else { return true }
            return filterSet.contains(String(stripped))
        }
        return Set(filtered)
    }

    private static func getCoverageReportAsJSON(resultFileURL: URL, shell: Commandline) throws -> CoverageReport {
        let arguments = ["xccov", "view", "--report", "--json", resultFileURL.path]
        let coverageData = try shell.execute(program: "/usr/bin/xcrun", with: arguments)
        return try JSONDecoder().decode(CoverageReport.self, from: coverageData)
    }

    struct CodeCoverageParseResult {
        let lines: [String]
        let executableLines: Int
        let coveredLines: Int
    }
}

extension NumberFormatter {
    func unwrappedString(for input: Double?) -> String {
        return string(for: input) ?? ""
    }
}
