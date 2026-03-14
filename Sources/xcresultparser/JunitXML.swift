//
//  JunitXML.swift
//  xcresult2text
//
//  Created by Alex da Franca on 10.06.21.
//

import Foundation

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

    private let dataProvider: JunitXMLDataProviding
    private let projectRoot: URL?
    private let testReportFormat: TestReportFormat
    private let relativePathNames: Bool
    private let shell: Commandline

    private let nodeNames: NodeNames

    private var numFormatter: NumberFormatter = {
        let numFormatter = NumberFormatter()
        numFormatter.maximumFractionDigits = 3
        numFormatter.locale = Locale(identifier: "en_US")
        return numFormatter
    }()

    // MARK: - Initializer

    public init(
        with url: URL,
        projectRoot: String = "",
        format: TestReportFormat = .junit,
        relativePathNames: Bool = true
    ) throws {
        let dataProvider = try XCResultToolJunitXMLDataProvider(url: url)
        self.init(
            dataProvider: dataProvider,
            projectRoot: projectRoot,
            format: format,
            relativePathNames: relativePathNames
        )
    }

    init(
        dataProvider: JunitXMLDataProviding,
        projectRoot: String = "",
        format: TestReportFormat = .junit,
        relativePathNames: Bool = true,
        shell: Commandline = Shell()
    ) {
        self.dataProvider = dataProvider
        var isDirectory: ObjCBool = false
        self.projectRoot = if SharedInstances.fileManager.fileExists(atPath: projectRoot, isDirectory: &isDirectory),
                              isDirectory.boolValue == true {
            URL(fileURLWithPath: projectRoot)
        } else {
            nil
        }

        testReportFormat = format
        nodeNames = if testReportFormat == .sonar {
            NodeNames.sonarNodeNames
        } else {
            NodeNames.defaultNodeNames
        }
        self.relativePathNames = relativePathNames
        self.shell = shell
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
            let metrics = dataProvider.metrics
            testsuites.addAttribute(name: "tests", stringValue: String(metrics.testsCount))
            testsuites.addAttribute(name: "failures", stringValue: String(metrics.testsFailedCount))
            testsuites.addAttribute(name: "errors", stringValue: "0") // apparently Jenkins needs this?!
        }

        let testActions = dataProvider.testActions
        guard !testActions.isEmpty else {
            return xml.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
        }

        var overallTestSuiteDuration = 0.0
        for testAction in testActions {
            let testPlanRunSummaries = testAction.testPlanRunSummaries
            let failureSummaries = testAction.failureSummaries

            if testReportFormat != .sonar {
                let startDate = testAction.startedTime
                let endDate = testAction.endedTime
                let duration = endDate.timeIntervalSince(startDate)
                overallTestSuiteDuration += duration
            }

            for thisSummary in testPlanRunSummaries {
                for thisTestableSummary in thisSummary.testableSummaries {
                    for group in thisTestableSummary.tests {
                        let groupTestsuites = createTestSuite(
                            group,
                            failureSummaries: failureSummaries,
                            configurationName: thisSummary.name ?? "Unnamed configuration"
                        )
                        for testsuite in groupTestsuites {
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

        // Add session-level failures that weren't associated with any specific test
        // These occur when Issue.record() is called outside a test's task context
        addSessionLevelFailures(to: testsuites)

        return xml.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
    }

    // only used in unit testing
    static func resetCachedPathnames() {
        JunitTestGroup.resetCachedPathnames()
    }

    // MARK: - Private interface

    private func createTestSuite(
        _ group: JunitTestGroup,
        failureSummaries: [JunitFailureSummary],
        configurationName: String,
        testDirectory: String = ""
    ) -> [XMLElement] {
        guard group.identifierString.hasSuffix(".xctest") || group.subtestGroups.isEmpty else {
            return group.subtestGroups.reduce([XMLElement]()) {
                rslt,
                    subGroup in
                return rslt + createTestSuite(
                    subGroup,
                    failureSummaries: failureSummaries,
                    configurationName: configurationName,
                    testDirectory: subGroup.identifierString
                )
            }
        }
        if group.subtestGroups.isEmpty {
            return [
                createTestSuiteFinally(
                    group,
                    tests: group.subtests,
                    failureSummaries: failureSummaries,
                    testDirectory: testDirectory,
                    configurationName: configurationName
                )
            ]
        } else {
            if testReportFormat == .sonar {
                var nodes = [XMLElement]()
                for subGroup in group.subtestGroups {
                    let node = subGroup.sonarFileXML(
                        projectRoot: projectRoot,
                        configurationName: configurationName,
                        relativePathNames: relativePathNames,
                        shell: shell
                    )
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
        _ group: JunitTestGroup,
        tests: [JunitTest],
        failureSummaries: [JunitFailureSummary],
        testDirectory: String = "",
        configurationName: String
    ) -> XMLElement {
        let node = testReportFormat == .sonar ?
            group.sonarFileXML(
                projectRoot: projectRoot,
                configurationName: configurationName,
                relativePathNames: relativePathNames,
                shell: shell
            ) : group.testSuiteXML(numFormatter: numFormatter)

        for thisTest in tests {
            let testcase = createTestCase(
                test: thisTest,
                classname: group.nameString,
                failureSummaries: failureSummaries
            )
            node.addChild(testcase)
        }
        return node
    }

    private func createTestCases(
        for name: String, tests: [JunitTest], failureSummaries: [JunitFailureSummary]
    ) -> [XMLElement] {
        var combined = [XMLElement]()
        for thisTest in tests {
            let testcase = createTestCase(
                test: thisTest,
                classname: name,
                failureSummaries: failureSummaries
            )
            combined.append(testcase)
        }
        return combined
    }

    private func createTestCase(
        test: JunitTest, classname: String, failureSummaries: [JunitFailureSummary]
    ) -> XMLElement {
        let testcase = test.xmlNode(
            classname: classname,
            numFormatter: numFormatter,
            format: testReportFormat,
            nodeNames: nodeNames
        )
        if test.isFailed {
            let summaries = test.failureSummaries(in: failureSummaries)
            if summaries.isEmpty {
                testcase.addChild(failureWithoutSummary)
            } else {
                for summary in summaries {
                    testcase.addChild(summary.failureXML(projectRoot: projectRoot))
                }
            }
        } else if test.isSkipped {
            testcase.addChild(skippedWithoutSummary)
        }
        return testcase
    }

    private var failureWithoutSummary: XMLElement {
        return XMLElement(name: "failure")
    }

    private var skippedWithoutSummary: XMLElement {
        return XMLElement(name: "skipped")
    }

    private func addSessionLevelFailures(to testsuites: XMLElement) {
        // Get session-level failures that weren't matched to any specific test
        let unmatchedFailures = dataProvider.sessionLevelFailures
        
        guard !unmatchedFailures.isEmpty else { return }
        
        // For JUnit format, create a separate test suite for session-level failures
        // For Sonar format, we skip this as it expects file-based organization
        if testReportFormat != .sonar {
            let sessionSuite = XMLElement(name: "testsuite")
            sessionSuite.addAttribute(name: "name", stringValue: "Session-level issues")
            sessionSuite.addAttribute(name: "tests", stringValue: String(unmatchedFailures.count))
            sessionSuite.addAttribute(name: "failures", stringValue: String(unmatchedFailures.count))
            sessionSuite.addAttribute(name: "errors", stringValue: "0")
            sessionSuite.addAttribute(name: "time", stringValue: "0")
            
            for failure in unmatchedFailures {
                let testcase = XMLElement(name: nodeNames.testcaseName)
                let testName = failure.testCaseName.isEmpty ? "Unknown test" : failure.testCaseName
                testcase.addAttribute(name: "name", stringValue: testName)
                if !nodeNames.testcaseClassNameName.isEmpty {
                    testcase.addAttribute(name: nodeNames.testcaseClassNameName, stringValue: failure.producingTarget ?? "Session")
                }
                if !nodeNames.testcaseDurationName.isEmpty {
                    testcase.addAttribute(name: nodeNames.testcaseDurationName, stringValue: "0")
                }
                testcase.addChild(failure.failureXML(projectRoot: projectRoot))
                sessionSuite.addChild(testcase)
            }
            
            testsuites.addChild(sessionSuite)
        }
    }
}

extension XMLElement {
    func addAttribute(name: String, stringValue: String) {
        if let attr = XMLNode.attribute(withName: name, stringValue: stringValue) as? XMLNode {
            addAttribute(attr)
        }
    }
}

extension JunitTest {
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
            let correctedTime: String = if format == .sonar {
                String(max(1, Int(time * 1000)))
            } else {
                numFormatter.unwrappedString(for: time)
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

    func failureSummaries(in summaries: [JunitFailureSummary]) -> [JunitFailureSummary] {
        return summaries.filter { summary in
            return summary.testCaseName == identifier?.replacingOccurrences(of: "/", with: ".") ||
                summary.testCaseName == "-[\(identifier?.replacingOccurrences(of: "/", with: " ") ?? "")]"
        }
    }
}

private extension JunitTestGroup {
    private static let cacheLock = NSLock()
    private static var cachedPathnames = [String: String]()

    struct TestMetrics {
        let tests: Int
        let failures: Int
    }

    var identifierString: String {
        return identifier ?? ""
    }

    var nameString: String {
        return name ?? "No-name"
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

    func sonarFileXML(projectRoot: URL?, configurationName: String, relativePathNames: Bool = true, shell: Commandline) -> XMLElement {
        let testsuite = XMLElement(name: "file")
        testsuite.addAttribute(
            name: "path",
            stringValue: classPath(in: projectRoot, relativePathNames: relativePathNames, shell: shell)
        )
        testsuite.addAttribute(name: "configuration", stringValue: configurationName)
        return testsuite
    }

    // only used in unit testing
    static func resetCachedPathnames() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cachedPathnames.removeAll()
    }

    static func resolvePathFromCachedClassMap(for fileName: String) -> String? {
        guard !fileName.contains("/") else {
            return fileName
        }
        cacheLock.lock()
        defer { cacheLock.unlock() }
        let candidates = cachedPathnames.values.filter { $0.hasSuffix("/\(fileName)") || $0 == fileName }
        guard !candidates.isEmpty else {
            return nil
        }
        return candidates.max { lhs, rhs in
            lhs.components(separatedBy: "est").count < rhs.components(separatedBy: "est").count
        }
    }

    // MARK: - Private interface

    private func classPath(in projectRootUrl: URL?, relativePathNames: Bool = true, shell: Commandline) -> String {
        guard let projectRootUrl else {
            return identifierString
        }
        Self.cacheLock.lock()
        defer { Self.cacheLock.unlock() }
        if Self.cachedPathnames.isEmpty {
            cacheAllClassNames(in: projectRootUrl, relativePathNames: relativePathNames, shell: shell)
        }
        return Self.cachedPathnames[identifierString] ?? identifierString
    }

    private func cacheAllClassNames(in projectRootUrl: URL, relativePathNames: Bool = true, shell: Commandline) {
        let program = "/usr/bin/grep"
        let grepPathArgument = relativePathNames ? "." : projectRootUrl.path
        let arguments = [
            "-E",
            "-rio",
            "--include", "*.swift",
            "--include", "*.m",
            "--include", "*.mm",
            "^(?:public )?(?:final )?(?:public )?(?:(class|\\@implementation|struct) )[a-zA-Z0-9_]+",
            grepPathArgument
        ]
        guard let filelistData = try? shell.execute(program: program, with: arguments, at: projectRootUrl) else {
            return
        }
        let trimCharacterSet = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ":"))
        let result = String(decoding: filelistData, as: UTF8.self).components(separatedBy: "\n")
        for match in result {
            let items = match.components(separatedBy: ":")
            if items.count > 1,
               let path = items.first,
               !path.isEmpty,
               let className = items
               .dropFirst()
               .joined(separator: ":")
               .trimmingCharacters(in: trimCharacterSet)
               .components(separatedBy: .whitespaces)
               .last,
               !className.isEmpty {
                if let existingPath = Self.cachedPathnames[className] {
                    if existingPath.components(separatedBy: "est").count <= path.withoutLocalPrefix.components(separatedBy: "est").count {
                        Self.cachedPathnames[className] = path.withoutLocalPrefix
                    }
                } else {
                    Self.cachedPathnames[className] = path.withoutLocalPrefix
                }
            }
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

private extension String {
    var withoutLocalPrefix: String {
        if hasPrefix("./") {
            return String(dropFirst(2))
        }
        return self
    }
}

private extension JunitFailureSummary {
    func failureXML(projectRoot: URL? = nil) -> XMLElement {
        let failure = XMLElement(name: "failure")
        var value = message
        if let loc = documentLocation {
            if loc.contains("://"), let url = URL(string: loc) {
                let relative = relativePart(of: url, relativeTo: projectRoot)
                if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let line = comps.fragment?.components(separatedBy: "&").first(
                       where: { $0.starts(with: "StartingLineNumber") }
                   ),
                   let num = line.components(separatedBy: "=").last {
                    value += " (\(relative):\(num))"
                } else {
                    value += " (\(loc))"
                }
            } else {
                value += " (\(resolvedDocumentLocation(loc, projectRoot: projectRoot)))"
            }
        }
        if !value.isEmpty {
            let textNode = XMLNode(kind: .text)
            textNode.objectValue = value
            failure.addChild(textNode)
            let shortMessage = if let producingTarget {
                "\(issueType) in \(producingTarget): \(testCaseName)"
            } else {
                "\(issueType): \(testCaseName)"
            }
            failure.addAttribute(name: "message", stringValue: shortMessage)
            failure.addAttribute(name: "type", stringValue: issueType)
        }
        return failure
    }

    private func resolvedDocumentLocation(_ location: String, projectRoot: URL?) -> String {
        guard projectRoot != nil else {
            return location
        }
        let components = location.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard components.count == 2 else {
            return location
        }
        let file = String(components[0])
        let linePart = String(components[1])
        guard let resolvedPath = JunitTestGroup.resolvePathFromCachedClassMap(for: file) else {
            return location
        }
        return "\(resolvedPath):\(linePart)"
    }

    private func relativePart(of url: URL, relativeTo projectRoot: URL?) -> String {
        guard let projectRoot else {
            return url.path
        }
        let parts = url.path.components(separatedBy: "\(projectRoot.path)")
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
