//
//  XCResultFormatter.swift
//  xcresultkitten
//
//  Created by Alex da Franca on 31.05.21.
//

import Foundation

public struct XCResultFormatter {
    private enum SummaryField: String {
        case errors, warnings, analyzerWarnings, tests, failed, skipped, duration, date
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

    private enum FormattedTestStatus {
        case passed
        case failed
        case skipped
        case expectedFailure
    }

    private struct FormattedTest {
        let identifier: String
        let name: String
        let duration: Double?
        let status: FormattedTestStatus

        var isFailed: Bool {
            status == .failed
        }

        var isSkipped: Bool {
            status == .skipped
        }

        var isExpectedFailure: Bool {
            status == .expectedFailure
        }

        var isSuccessful: Bool {
            status == .passed
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

    private static let numberStyle = FloatingPointFormatStyle<Double>
        .number
        .locale(Locale(identifier: "en_US_POSIX"))
        .precision(.fractionLength(0 ... 4))

    private static let percentStyle = FloatingPointFormatStyle<Double>
        .number
        .locale(Locale(identifier: "en_US_POSIX"))
        .precision(.fractionLength(0 ... 1))

    private static let iso8601UTCStyle = Date.ISO8601FormatStyle(
        timeZone: TimeZone(secondsFromGMT: 0) ?? .current
    )

    // MARK: - Initializer

    public init(
        with url: URL,
        formatter: XCResultFormatting,
        coverageTargets: [String] = [],
        failedTestsOnly: Bool = false,
        summaryFields: String = "errors|warnings|analyzerWarnings|tests|failed|skipped|duration|date",
        coverageReportFormat: CoverageReportFormat = .methods
    ) throws {
        try self.init(
            with: url,
            formatter: formatter,
            coverageTargets: coverageTargets,
            failedTestsOnly: failedTestsOnly,
            summaryFields: summaryFields,
            coverageReportFormat: coverageReportFormat,
            xcResultToolClient: XCResultToolClient(),
            xcCovClient: XCCovClient()
        )
    }

    init(
        with url: URL,
        formatter: XCResultFormatting,
        coverageTargets: [String] = [],
        failedTestsOnly: Bool = false,
        summaryFields: String = "errors|warnings|analyzerWarnings|tests|failed|skipped|duration|date",
        coverageReportFormat: CoverageReportFormat = .methods,
        xcResultToolClient: XCResultToolProviding,
        xcCovClient: XCCovProviding
    ) throws {
        buildResults = try xcResultToolClient.getBuildResults(path: url)
        testSummary = try xcResultToolClient.getTestSummary(path: url)
        tests = try xcResultToolClient.getTests(path: url)
        outputFormatter = formatter
        coverageReport = try? xcCovClient.getCoverageReport(path: url)
        let targetSelection = CoverageTargetSelection(
            with: coverageTargets,
            from: coverageReport?.targets.map(\.name) ?? []
        )
        guard targetSelection.unmatchedRequested.isEmpty else {
            throw CoverageConverterError.unknownCoverageTargets(
                requested: targetSelection.unmatchedRequested.sorted(),
                available: targetSelection.availableTargets.sorted()
            )
        }
        self.coverageTargets = targetSelection.selectedTargets
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
        if summaryFields.enabledFields.contains(.duration),
           let durationString = executionDurationString() {
            lines.append(
                outputFormatter.resultSummaryLine(
                    "Execution time = \(durationString)s",
                    failed: false
                )
            )
        }
        if summaryFields.enabledFields.contains(.date),
           let executionDateString = executionDateString() {
            lines.append(
                outputFormatter.resultSummaryLine(
                    "Execution date = \(executionDateString)",
                    failed: false
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
        if summaryFields.enabledFields.contains(.duration),
           let durationString = executionDurationString() {
            summary += "; Execution time = \(durationString)s"
        }
        if summaryFields.enabledFields.contains(.date),
           let executionDateString = executionDateString() {
            summary += "; Execution date = \(executionDateString)"
        }
        return summary
    }

    private func executionDurationString() -> String? {
        guard let start = testSummary.startTime,
              let finish = testSummary.finishTime else {
            return nil
        }
        let duration = max(0, finish - start)
        let formatted = duration.formatted(Self.numberStyle)
        return formatted.isEmpty ? nil : formatted
    }

    private func executionDateString() -> String? {
        guard let start = testSummary.startTime else {
            return nil
        }
        let date = Date(timeIntervalSince1970: start)
        return date.formatted(Self.iso8601UTCStyle)
    }

    private func createTestDetailsString() -> [String] {
        var lines = [String]()
        let runDestination = tests.devices.first?.deviceName ?? "Unknown destination"
        let failureMessageDetails = failureMessageDetailsByTestIdentifier()

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
                    lines += createTestSummaryInfo(
                        group,
                        level: 0,
                        failureSummaries: testSummary.testFailures,
                        failureMessageDetails: failureMessageDetails
                    )
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
        failureSummaries: [XCTestFailure],
        failureMessageDetails: [String: [FailureMessageDetail]]
    ) -> [String] {
        var lines = [String]()
        if failedTestsOnly,
           !group.hasFailedTests {
            return lines
        }
        let header = "\(group.name) (\(formattedDurationString(for: group.duration)))"

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
            lines += createTestSummaryInfo(
                subGroup,
                level: level + 1,
                failureSummaries: failureSummaries,
                failureMessageDetails: failureMessageDetails
            )
        }
        if !outputFormatter.accordionOpenTag.isEmpty {
            lines.append(outputFormatter.accordionOpenTag)
        }
        for thisTest in group.subtests {
            if !failedTestsOnly || thisTest.isFailed {
                lines.append(
                    actionTestFileStatusString(
                        for: thisTest,
                        failureSummaries: failureSummaries,
                        failureMessageDetails: failureMessageDetails
                    )
                )
            }
        }
        if !outputFormatter.accordionCloseTag.isEmpty {
            lines.append(outputFormatter.accordionCloseTag)
        }
        return lines
    }

    private func actionTestFileStatusString(
        for testData: FormattedTest,
        failureSummaries: [XCTestFailure],
        failureMessageDetails: [String: [FailureMessageDetail]]
    ) -> String {
        let duration = formattedDurationString(for: testData.duration)
        let icon = actionTestFileStatusStringIcon(testData: testData)
        let testTitle = "\(icon) \(testData.name) (\(duration))"
        let testCaseName = testData.identifier
        if let summary = failureSummaries.first(where: {
            $0.testIdentifierString == testCaseName ||
                $0.testIdentifierString.replacingOccurrences(of: "/", with: ".") == testCaseName
        }) {
            let candidates = failureMessageDetails[summary.testIdentifierString] ??
                failureMessageDetails[summary.testIdentifierString.replacingOccurrences(of: "/", with: ".")] ?? []
            let matchingDetail = bestFailureMessage(for: summary, in: candidates)
            let enrichedMessage = if let matchingDetail {
                "\(matchingDetail.documentLocation): \(matchingDetail.message)"
            } else {
                summary.failureText
            }
            return actionTestFailureStatusString(with: testTitle, message: enrichedMessage)
        }
        return outputFormatter.singleTestItem(testTitle, failed: testData.isFailed)
    }

    private func actionTestFileStatusStringIcon(testData: FormattedTest) -> String {
        if testData.isSuccessful {
            return outputFormatter.testPassIcon
        }

        if testData.isExpectedFailure {
            return outputFormatter.testExpectedFailureIcon
        }

        if testData.isSkipped {
            return outputFormatter.testSkipIcon
        }

        return outputFormatter.testFailIcon
    }

    private func actionTestFailureStatusString(with header: String, message: String) -> String {
        return outputFormatter.failedTestItem(header, message: message)
    }

    private func formattedDurationString(for duration: Double?) -> String {
        guard let duration else {
            return ""
        }
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        }
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
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
        let covPercent = (fraction * 100).formatted(Self.percentStyle)
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

        let covPercent = (target.lineCoverage * 100).formatted(Self.percentStyle)
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
        let covPercent = (file.lineCoverage * 100).formatted(Self.percentStyle)
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
                let covPercentLine = (function.lineCoverage * 100).formatted(Self.percentStyle)
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
        if node.nodeType == .testPlanConfiguration,
           node.name == configuration.configurationName || node.nodeIdentifier == configuration.configurationId {
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
        let tests = children.mapTests(
            testClassName: nextTestClassName,
            mapTest: mapTest(node:testClassName:),
            mapArgumentTest: { mappedArgumentTest in
                FormattedTest(
                    identifier: mappedArgumentTest.identifier,
                    name: mappedArgumentTest.name,
                    duration: mappedArgumentTest.duration,
                    status: testStatus(for: mappedArgumentTest.result)
                )
            }
        )

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
        let identifier: String = if let testClassName {
            "\(testClassName)/\(node.name)"
        } else {
            node.name
        }
        return FormattedTest(
            identifier: identifier,
            name: node.name,
            duration: node.durationInSeconds,
            status: testStatus(for: result)
        )
    }

    private func testStatus(for result: XCTestResult) -> FormattedTestStatus {
        switch result {
        case .failed:
            return .failed
        case .skipped:
            return .skipped
        case .expectedFailure:
            return .expectedFailure
        case .passed, .unknown:
            return .passed
        }
    }

    private func mappedGroupName(for node: XCTestNode) -> String {
        switch node.nodeType {
        case .unitTestBundle, .uiTestBundle:
            return node.name.hasSuffix(".xctest") ? node.name : "\(node.name).xctest"
        default:
            return node.name
        }
    }

    private func failureMessageDetailsByTestIdentifier() -> [String: [FailureMessageDetail]] {
        var result = [String: [FailureMessageDetail]]()
        for node in tests.testNodes {
            collectFailureMessages(
                in: node,
                currentTestIdentifier: nil,
                currentTestClassName: nil,
                into: &result
            )
        }
        return result
    }

    private func collectFailureMessages(
        in node: XCTestNode,
        currentTestIdentifier: String?,
        currentTestClassName: String?,
        into result: inout [String: [FailureMessageDetail]]
    ) {
        var currentIdentifier = currentTestIdentifier
        let nextTestClassName: String? = if node.nodeType == .testSuite {
            node.name
        } else {
            currentTestClassName
        }
        if node.nodeType == .testCase {
            currentIdentifier = node.nodeIdentifier ?? {
                if let nextTestClassName {
                    return "\(nextTestClassName)/\(node.name)"
                }
                return node.name
            }()
        }

        if node.nodeType == .failureMessage,
           let currentIdentifier,
           let detail = FailureMessageDetail(from: node.name) {
            result[currentIdentifier, default: []].append(detail)
            let dotKey = currentIdentifier.replacingOccurrences(of: "/", with: ".")
            result[dotKey, default: []].append(detail)
        }

        for child in node.children ?? [] {
            collectFailureMessages(
                in: child,
                currentTestIdentifier: currentIdentifier,
                currentTestClassName: nextTestClassName,
                into: &result
            )
        }
    }

    private func bestFailureMessage(for failure: XCTestFailure, in candidates: [FailureMessageDetail]) -> FailureMessageDetail? {
        candidates.first {
            $0.message == failure.failureText ||
                $0.message.contains(failure.failureText) ||
                failure.failureText.contains($0.message)
        } ?? candidates.first
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
