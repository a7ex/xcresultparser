//
//  JunitXML.swift
//  xcresult2text
//
//  Created by Alex da Franca on 10.06.21.
//

import Foundation
import XCResultKit

enum TestReportFormat {
    case junit, sonar
}

struct NodeNames {
    let testsuitesName: String
    let testcaseName: String
    let testcaseDurationName: String
    let testcaseClassNameName: String
}

fileprivate var nodeNames = NodeNames(
    testsuitesName: "testsuites",
    testcaseName: "testcase",
    testcaseDurationName: "time",
    testcaseClassNameName: "classname"
)

struct JunitXML {
    
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
    
    
    init?(with url: URL,
          projectRoot: String = "",
          format: TestReportFormat = .junit) {
        resultFile = XCResultFile(url: url)
        guard let record = resultFile.getInvocationRecord() else {
            return nil
        }
        self.projectRoot = projectRoot
        invocationRecord = record
        testReportFormat = format
        if testReportFormat == .sonar {
            nodeNames = NodeNames(
                testsuitesName: "testExecutions",
                testcaseName: "testCase",
                testcaseDurationName: "duration",
                testcaseClassNameName: ""
            )
        }
    }
    
    func createRootElement() -> XMLElement {
        let element = XMLElement(name: nodeNames.testsuitesName)
        element.addAttribute(name: "version", stringValue: "1")
        return element
    }
    
    var xmlString: String {
        let testsuites = createRootElement()
        let xml = XMLDocument(rootElement: testsuites)
        xml.characterEncoding = "UTF-8"
        
        if testReportFormat != .sonar {
            let metrics = invocationRecord.metrics
            let testsCount = metrics.testsCount ?? 0
            testsuites.addAttribute(name: "tests", stringValue: String(testsCount))
            let testsFailedCount = metrics.testsFailedCount ?? 0
            testsuites.addAttribute(name: "failures", stringValue: String(testsFailedCount))
        }
        
        let testAction = invocationRecord.actions.first { $0.schemeCommandName == "Test" }
        guard let testsId = testAction?.actionResult.testsRef?.id,
              let testPlanRun = resultFile.getTestPlanRunSummaries(id: testsId) else {
            return xml.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
        }
        
        if testReportFormat != .sonar {
            if let date = testAction?.startedTime {
                let dateFormatter = ISO8601DateFormatter()
                testsuites.addAttribute(name: "timestamp", stringValue: dateFormatter.string(from: date))
                if let ended = testAction?.endedTime {
                    let duration = ended.timeIntervalSince(date)
                    testsuites.addAttribute(name: "time", stringValue: String(duration))
                }
            }
            if let runDestination = testAction?.runDestination {
                testsuites.addChild(runDestinationXML(runDestination))
            }
        }
        let testPlanRunSummaries = testPlanRun.summaries
        let failureSummaries = invocationRecord.issues.testFailureSummaries
        
        for thisSummary in testPlanRunSummaries {
            for thisTestableSummary in thisSummary.testableSummaries {
                for group in thisTestableSummary.tests {
                    for testsuite in createTestSuite(group, failureSummaries: failureSummaries) {
                        testsuites.addChild(testsuite)
                    }
                }
            }
        }
        return xml.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
    }
    
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
                return rslt + createTestSuite(subGroup, failureSummaries: failureSummaries, testDirectory: subGroup.identifierString)
            }
        }
        if group.subtestGroups.isEmpty {
            return [
                createTestSuiteFinally(group, tests: group.subtests, failureSummaries: failureSummaries, testDirectory: testDirectory)
            ]
        } else {
            let combined = group.subtestGroups.reduce([XMLElement]()) { rslt, subGroup in
                return rslt + createTestCases(for: subGroup.nameString, tests: subGroup.subtests, failureSummaries: failureSummaries)
            }
            let node = testReportFormat == .sonar ? group.sonarFileXML: group.testSuiteXML
            combined.forEach { node.addChild($0) }
            return [node]
        }
    }
    
    private func createTestSuiteFinally(
        _ group: ActionTestSummaryGroup,
        tests: [ActionTestMetadata],
        failureSummaries: [TestFailureIssueSummary],
        testDirectory: String = ""
    ) -> XMLElement {
        let node = testReportFormat == .sonar ? group.sonarFileXML: group.testSuiteXML
        for thisTest in tests {
            let testcase = thisTest.xmlNode(classname: group.nameString)
            if thisTest.isFailed {
                let summary = failureSummaries.first { summary in
                    return summary.testCaseName == self.assembledIdentifier(thisTest.identifier)
                }
                if let summary = summary {
                    testcase.addChild(summary.failureXML(projectRoot: projectRoot))
                } else {
                    testcase.addChild(failureWithoutSummary)
                }
            }
            node.addChild(testcase)
        }
        return node
    }
    
    private func createTestCases(for name: String, tests: [ActionTestMetadata], failureSummaries: [TestFailureIssueSummary]) -> [XMLElement] {
        var combined = [XMLElement]()
        for thisTest in tests {
            let testcase = thisTest.xmlNode(classname: name)
            if thisTest.isFailed {
                let identifier = self.assembledIdentifier(thisTest.identifier);
                if let summary = failureSummaries.first(where: { $0.testCaseName == identifier }) {
                    testcase.addChild(summary.failureXML(projectRoot: projectRoot))
                } else {
                    testcase.addChild(failureWithoutSummary)
                }
            }
            combined.append(testcase)
        }
        return combined
    }

    private func assembledIdentifier(_ identifier: String) -> String {
        return "-[" + identifier.replacingOccurrences(of: "/", with: " ") + "]";
    }
    
    private var failureWithoutSummary: XMLElement {
        return XMLElement(name: "failure")
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
    func xmlNode(classname: String, format: TestReportFormat = .junit) -> XMLElement {
        let testcase = XMLElement(name: nodeNames.testcaseName)
        testcase.addAttribute(name: "name", stringValue: name)
        if let time = duration,
           !nodeNames.testcaseDurationName.isEmpty {
            let correctedTime = format == .sonar ? time * 1000: time
            testcase.addAttribute(name: nodeNames.testcaseDurationName, stringValue: String(correctedTime))
            if !nodeNames.testcaseClassNameName.isEmpty {
                testcase.addAttribute(name: nodeNames.testcaseClassNameName, stringValue: classname)
            }
        }
        return testcase
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
    
    var testSuiteXML: XMLElement {
        let testsuite = XMLElement(name: "testsuite")
        testsuite.addAttribute(name: "name", stringValue: nameString)
        let stats = statistics
        testsuite.addAttribute(name: "tests", stringValue: String(stats.tests))
        testsuite.addAttribute(name: "failures", stringValue: String(stats.failures))
        testsuite.addAttribute(name: "time", stringValue: String(duration))
        return testsuite
    }
    
    var sonarFileXML: XMLElement {
        let testsuite = XMLElement(name: "file")
        testsuite.addAttribute(name: "path", stringValue: identifierString)
        return testsuite
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
                   let line = comps.fragment?.components(separatedBy: "&").first(where: { $0.starts(with: "StartingLineNumber") }),
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
            String(relative.dropFirst()):
            relative
    }
}

private extension Bool {
    var intValue: Int {
        return self ? 1: 0
    }
}
