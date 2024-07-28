//
//  JunitXML.swift
//  xcresult2text
//
//  Created by Alex da Franca on 10.06.21.
//

import Foundation
import XCResultKit

public enum TestReportFormat {
    case junit, sonar
}

struct NodeNames {
    let testsuitesName: String
    let testcaseName: String
    let testcaseDurationName: String
    let testcaseClassNameName: String
    
    static let defaultNodeNames = NodeNames(
        testsuitesName: "testsuites",
        testcaseName: "testcase",
        testcaseDurationName: "time",
        testcaseClassNameName: "classname"
    )
    
    static let sonarNodeNames = NodeNames(
        testsuitesName: "testExecutions",
        testcaseName: "testCase",
        testcaseDurationName: "duration",
        testcaseClassNameName: ""
    )
}

public struct JunitXML: XmlSerializable {
    struct TestrunProperty {
        let name: String
        let value: String

        var xmlNode: XMLElement {
            let prop = XMLElement(name: "property")
            prop.addAttribute(name: name, stringValue: value)
            return prop
        }
    }

    // MARK: - Properties

    private let resultFile: XCResultFile
    private let projectRoot: String
    private let invocationRecord: ActionsInvocationRecord
    private let testReportFormat: TestReportFormat
    
    private let nodeNames: NodeNames

    private var numFormatter: NumberFormatter = {
        let numFormatter = NumberFormatter()
        numFormatter.maximumFractionDigits = 3
        numFormatter.locale = Locale(identifier: "en_US")
        return numFormatter
    }()

    public init?(
        with url: URL,
        projectRoot: String = "",
        format: TestReportFormat = .junit
    ) {
        resultFile = XCResultFile(url: url)
        guard let record = resultFile.getInvocationRecord() else {
            return nil
        }
        self.projectRoot = projectRoot
        invocationRecord = record
        testReportFormat = format
        if testReportFormat == .sonar {
            nodeNames = NodeNames.sonarNodeNames
        } else {
            nodeNames = NodeNames.defaultNodeNames
        }
    }

    func createRootElement() -> XMLElement {
        let element = XMLElement(name: nodeNames.testsuitesName)
        if testReportFormat == .sonar {
            element.addAttribute(name: "version", stringValue: "1")
        }
        return element
    }

    public var xmlString: String {
        let testsuites = createRootElement()
        let xml = XMLDocument(rootElement: testsuites)
        xml.characterEncoding = "UTF-8"

        if testReportFormat != .sonar {
            let metrics = invocationRecord.metrics
            let testsCount = metrics.testsCount ?? 0
            testsuites.addAttribute(name: "tests", stringValue: String(testsCount))
            let testsFailedCount = metrics.testsFailedCount ?? 0
            testsuites.addAttribute(name: "failures", stringValue: String(testsFailedCount))
            testsuites.addAttribute(name: "errors", stringValue: "0") // apparently Jenkins needs this?!
        }

        let testActions = invocationRecord.actions.filter { $0.schemeCommandName == "Test" }
        guard !testActions.isEmpty else {
            return xml.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
        }

        var overallTestSuiteDuration = 0.0
        for testAction in testActions {
            guard let testsId = testAction.actionResult.testsRef?.id,
                  let testPlanRun = resultFile.getTestPlanRunSummaries(id: testsId) else {
                continue
            }

            let testPlanRunSummaries = testPlanRun.summaries
            let failureSummaries = invocationRecord.issues.testFailureSummaries

            if testReportFormat != .sonar {
                let startDate = testAction.startedTime
                let endDate = testAction.endedTime
                let duration = endDate.timeIntervalSince(startDate)
                overallTestSuiteDuration += duration
            }

            for thisSummary in testPlanRunSummaries {
                for thisTestableSummary in thisSummary.testableSummaries {
                    for group in thisTestableSummary.tests {
                        for testsuite in createTestSuite(group, failureSummaries: failureSummaries) {
                            testsuites.addChild(testsuite)
                        }
                    }
                }
            }
        }

        if testReportFormat != .sonar {
            testsuites.addAttribute(
                name: "time", stringValue: numFormatter.unwrappedString(for: overallTestSuiteDuration)
            )
        }

        return xml.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
    }

    // The XMLElement produced by this function is not allowed in the junit XML format and thus unused.
    // It is kept in case it serves another format.
    private func runDestinationXML(_ destination: ActionRunDestinationRecord) -> XMLElement {
        let properties = XMLElement(name: "properties")
        if !destination.displayName.isEmpty {
            properties.addChild(TestrunProperty(name: "destination", value: destination.displayName).xmlNode)
        }
        if !destination.targetArchitecture.isEmpty {
            properties.addChild(TestrunProperty(name: "architecture", value: destination.targetArchitecture).xmlNode)
        }
        let record = destination.targetSDKRecord
        if !record.name.isEmpty {
            properties.addChild(TestrunProperty(name: "sdk", value: record.name).xmlNode)
        }
        return properties
    }

    private func createTestSuite(
        _ group: ActionTestSummaryGroup,
        failureSummaries: [TestFailureIssueSummary],
        testDirectory: String = ""
    ) -> [XMLElement] {
        guard group.identifierString.hasSuffix(".xctest") || group.subtestGroups.isEmpty else {
            return group.subtestGroups.reduce([XMLElement]()) { rslt, subGroup in
                return rslt + createTestSuite(
                    subGroup, failureSummaries: failureSummaries, testDirectory: subGroup.identifierString
                )
            }
        }
        if group.subtestGroups.isEmpty {
            return [
                createTestSuiteFinally(
                    group, tests: group.subtests, failureSummaries: failureSummaries, testDirectory: testDirectory
                )
            ]
        } else {
            if testReportFormat == .sonar {
                var nodes = [XMLElement]()
                for subGroup in group.subtestGroups {
                    let node = subGroup.sonarFileXML(projectRoot: projectRoot)
                    let testcases = createTestCases(
                        for: subGroup.nameString, tests: subGroup.subtests, failureSummaries: failureSummaries
                    )
                    testcases.forEach { node.addChild($0) }
                    nodes.append(node)
                }
                return nodes
            } else {
                let combined = group.subtestGroups.reduce([XMLElement]()) { rslt, subGroup in
                    return rslt + createTestCases(
                        for: subGroup.nameString, tests: subGroup.subtests, failureSummaries: failureSummaries
                    )
                }
                let node = group.testSuiteXML(numFormatter: numFormatter)
                combined.forEach { node.addChild($0) }
                return [node]
            }
        }
    }

    private func createTestSuiteFinally(
        _ group: ActionTestSummaryGroup,
        tests: [ActionTestMetadata],
        failureSummaries: [TestFailureIssueSummary],
        testDirectory: String = ""
    ) -> XMLElement {
        let node = testReportFormat == .sonar ?
            group.sonarFileXML(projectRoot: projectRoot) :
            group.testSuiteXML(numFormatter: numFormatter)

        for thisTest in tests {
            let testcase = thisTest.xmlNode(
                classname: group.nameString,
                numFormatter: numFormatter,
                format: testReportFormat,
                nodeNames: nodeNames
            )
            if thisTest.isFailed {
                if let summary = thisTest.failureSummary(in: failureSummaries) {
                    testcase.addChild(summary.failureXML(projectRoot: projectRoot))
                } else {
                    testcase.addChild(failureWithoutSummary)
                }
            }
            node.addChild(testcase)
        }
        return node
    }

    private func createTestCases(
        for name: String, tests: [ActionTestMetadata], failureSummaries: [TestFailureIssueSummary]
    ) -> [XMLElement] {
        var combined = [XMLElement]()
        for thisTest in tests {
            let testcase = thisTest.xmlNode(
                classname: name,
                numFormatter: numFormatter,
                format: testReportFormat,
                nodeNames: nodeNames
            )
            if thisTest.isFailed {
                if let summary = thisTest.failureSummary(in: failureSummaries) {
                    testcase.addChild(summary.failureXML(projectRoot: projectRoot))
                } else {
                    testcase.addChild(failureWithoutSummary)
                }
            } else if thisTest.isSkipped {
                testcase.addChild(skippedWithoutSummary)
            }
            combined.append(testcase)
        }
        return combined
    }

    private var failureWithoutSummary: XMLElement {
        return XMLElement(name: "failure")
    }

    private var skippedWithoutSummary: XMLElement {
        return XMLElement(name: "skipped")
    }
}

extension XMLElement {
    func addAttribute(name: String, stringValue: String) {
        if let attr = XMLNode.attribute(withName: name, stringValue: stringValue) as? XMLNode {
            addAttribute(attr)
        }
    }
}

private extension ActionTestMetadata {
    func xmlNode(
        classname: String,
        numFormatter: NumberFormatter,
        format: TestReportFormat,
        nodeNames: NodeNames
    ) -> XMLElement {
        let testcase = XMLElement(name: nodeNames.testcaseName)
        testcase.addAttribute(name: "name", stringValue: name ?? "No-name")
        if let time = duration,
           !nodeNames.testcaseDurationName.isEmpty {
            let correctedTime: String
            if format == .sonar {
                correctedTime = String(max(1, Int(time * 1000)))
            } else {
                correctedTime = numFormatter.unwrappedString(for: time)
            }
            testcase.addAttribute(
                name: nodeNames.testcaseDurationName,
                stringValue: correctedTime
            )
            if !nodeNames.testcaseClassNameName.isEmpty {
                testcase.addAttribute(name: nodeNames.testcaseClassNameName, stringValue: classname)
            }
        }
        return testcase
    }
    
    func failureSummary(in summaries: [TestFailureIssueSummary]) -> TestFailureIssueSummary? {
        return summaries.first { summary in
            return summary.testCaseName == identifier?.replacingOccurrences(of: "/", with: ".") ||
                summary.testCaseName == "-[\(identifier?.replacingOccurrences(of: "/", with: " ") ?? "")]"
        }
    }
}

private extension ActionTestSummaryGroup {
    struct TestMetrics {
        let tests: Int
        let failures: Int
    }

    var identifierString: String {
        return identifier ?? ""
    }

    func testSuiteXML(numFormatter: NumberFormatter) -> XMLElement {
        let testsuite = XMLElement(name: "testsuite")
        testsuite.addAttribute(name: "name", stringValue: nameString)
        let stats = statistics
        testsuite.addAttribute(name: "tests", stringValue: String(stats.tests))
        testsuite.addAttribute(name: "failures", stringValue: String(stats.failures))
        testsuite.addAttribute(name: "errors", stringValue: "0") // apparently Jenkins needs this?!
        testsuite.addAttribute(name: "time", stringValue: numFormatter.unwrappedString(for: duration))
        return testsuite
    }

    func sonarFileXML(projectRoot: String) -> XMLElement {
        let testsuite = XMLElement(name: "file")
        testsuite.addAttribute(name: "path", stringValue: relativeFilenameGuess(in: projectRoot))
        return testsuite
    }

    private func relativeFilenameGuess(in projectRoot: String) -> String {
        guard !projectRoot.isEmpty else {
            return identifierString
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: projectRoot, isDirectory: &isDirectory),
              isDirectory.boolValue == true else {
            return identifierString
        }
        let url = URL(fileURLWithPath: projectRoot)
        let arguments = ["-rl", "--include", "*.swift", "class \(identifierString)[ |:]", "."]
        do {
            let filelistData = try Shell.execute(program: "/usr/bin/grep", with: arguments, at: url)
            guard let result = String(decoding: filelistData, as: UTF8.self).components(separatedBy: "\n").first,
                  !result.isEmpty else {
                return identifierString
            }
            if result.hasPrefix("./") {
                return String(result.dropFirst(2))
            }
            return result
        } catch {
            return identifierString
        }
    }

    private var statistics: TestMetrics {
        return TestMetrics(tests: numberOfTests, failures: numberOfFailures)
    }

    private var numberOfTests: Int {
        return subtests.count + subtestGroups.reduce(0) { result, group in
            return result + group.numberOfTests
        }
    }

    private var numberOfFailures: Int {
        let num = subtestGroups.reduce(0) { result, group in
            return result + group.numberOfFailures
        }
        return num + subtests.reduce(0) { result, test in
            return result + test.isFailed.intValue
        }
    }
}

private extension TestFailureIssueSummary {
    func failureXML(projectRoot: String = "") -> XMLElement {
        let failure = XMLElement(name: "failure")
        var value = message
        if let loc = documentLocationInCreatingWorkspace?.url {
            if let url = URL(string: loc) {
                let relative = relativePart(of: url, relativeTo: projectRoot)
                if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let line = comps.fragment?.components(separatedBy: "&").first(
                       where: { $0.starts(with: "StartingLineNumber") }),
                   let num = line.components(separatedBy: "=").last {
                    value += " (\(relative):\(num))"
                } else {
                    value += " (\(loc))"
                }
            } else {
                value += " (\(loc))"
            }
        }
        if !value.isEmpty {
            //            failure.addAttribute(name: "name", stringValue: value)
            let textNode = XMLNode(kind: .text)
            textNode.objectValue = value
            failure.addChild(textNode)
            failure.addAttribute(name: "message", stringValue: "short")
        }
        return failure
    }

    private func relativePart(of url: URL, relativeTo projectRoot: String) -> String {
        guard !projectRoot.isEmpty else {
            return url.path
        }
        let parts = url.path.components(separatedBy: "/\(projectRoot)")
        guard parts.count > 1 else {
            return url.path
        }
        let relative = parts[parts.count - 1]
        return relative.starts(with: "/") ?
            String(relative.dropFirst()) :
            relative
    }
}

private extension Bool {
    var intValue: Int {
        return self ? 1 : 0
    }
}
