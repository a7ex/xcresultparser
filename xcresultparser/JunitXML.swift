//
//  JunitXML.swift
//  xcresult2text
//
//  Created by Alex da Franca on 10.06.21.
//

import Foundation
import XCResultKit

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
    
    init?(with url: URL,
          projectRoot: String = "") {
        resultFile = XCResultFile(url: url)
        guard let record = resultFile.getInvocationRecord() else {
            return nil
        }
        self.projectRoot = projectRoot
        invocationRecord = record
    }
    
    var xmlString: String {
        let testsuites = XMLElement(name: "testsuites")
        let xml = XMLDocument(rootElement: testsuites)
        xml.characterEncoding = "UTF-8"
        
        let metrics = invocationRecord.metrics
        let testsCount = metrics.testsCount ?? 0
        testsuites.addAttribute(name: "tests", stringValue: String(testsCount))
        let testsFailedCount = metrics.testsFailedCount ?? 0
        testsuites.addAttribute(name: "failures", stringValue: String(testsFailedCount))
        
        let testAction = invocationRecord.actions.first { action in
            return action.schemeCommandName == "Test"
        }
        guard let testsId = testAction?.actionResult.testsRef?.id,
              let testPlanRun = resultFile.getTestPlanRunSummaries(id: testsId) else {
            return xml.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
        }
        
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
    
    private func createTestSuite(_ group: ActionTestSummaryGroup, failureSummaries: [TestFailureIssueSummary]) -> [XMLElement] {
        guard group.identifier.hasSuffix(".xctest") || group.subtestGroups.isEmpty else {
            var combined = [XMLElement]()
            for subGroup in group.subtestGroups {
                combined = combined + createTestSuite(subGroup, failureSummaries: failureSummaries)
            }
            return combined
        }
        if group.subtestGroups.isEmpty {
            return [
                createTestSuiteFinally(group, tests: group.subtests, failureSummaries: failureSummaries)
            ]
        } else {
            var combined = [XMLElement]()
            for subGroup in group.subtestGroups {
                combined = combined + createTestCases(for: subGroup.name, tests: subGroup.subtests, failureSummaries: failureSummaries)
            }
            let node = group.testSuiteXML
            for element in combined {
                node.addChild(element)
            }
            return [node]
        }
    }
    
    private func createTestSuiteFinally(_ group: ActionTestSummaryGroup, tests: [ActionTestMetadata], failureSummaries: [TestFailureIssueSummary]) -> XMLElement {
        let node = group.testSuiteXML
        for thisTest in tests {
            let testcase = thisTest.xmlNode(classname: group.name)
            if thisTest.isFailed {
                let summary = failureSummaries.first { summary in
                    return summary.testCaseName == thisTest.identifier.replacingOccurrences(of: "/", with: ".")
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
                let summary = failureSummaries.first { summary in
                    return summary.testCaseName == thisTest.identifier.replacingOccurrences(of: "/", with: ".")
                }
                if let summary = summary {
                    testcase.addChild(summary.failureXML(projectRoot: projectRoot))
                } else {
                    testcase.addChild(failureWithoutSummary)
                }
            }
            combined.append(testcase)
        }
        return combined
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
    func xmlNode(classname: String) -> XMLElement {
        let testcase = XMLElement(name: "testcase")
        testcase.addAttribute(name: "classname", stringValue: classname)
        testcase.addAttribute(name: "name", stringValue: name)
        if let time = duration {
            testcase.addAttribute(name: "time", stringValue: String(time))
        }
        return testcase
    }
}

private extension ActionTestSummaryGroup {
    struct TestMetrics {
        let tests: Int
        let failures: Int
    }
    
    var testSuiteXML: XMLElement {
        let testsuite = XMLElement(name: "testsuite")
        testsuite.addAttribute(name: "name", stringValue: name)
        let stats = statistics
        testsuite.addAttribute(name: "tests", stringValue: String(stats.tests))
        testsuite.addAttribute(name: "failures", stringValue: String(stats.failures))
        testsuite.addAttribute(name: "time", stringValue: String(duration))
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
                let relative: String = projectRoot.isEmpty ?
                    url.path:
                    url.path.components(separatedBy: "/\(projectRoot)/").last ?? url.path
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
            failure.addAttribute(name: "name", stringValue: value)
        }
        return failure
    }
}

private extension Bool {
    var intValue: Int {
        return self ? 1: 0
    }
}
