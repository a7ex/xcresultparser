//
//  XCResultToolJunitXMLDataProvider.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 20.02.26.
//

import Foundation

struct XCResultToolJunitXMLDataProvider: JunitXMLDataProviding {
    private let summary: XCSummary
    private let tests: XCTests

    init(url: URL, client: XCResultToolProviding = XCResultToolClient()) throws {
        summary = try client.getTestSummary(path: url)
        tests = try client.getTests(path: url)
    }

    var metrics: JunitInvocationMetrics {
        JunitInvocationMetrics(
            testsCount: summary.totalTestCount,
            testsFailedCount: summary.failedTests
        )
    }

    var testActions: [JunitTestAction] {
        let start = Date(timeIntervalSince1970: summary.startTime ?? 0)
        let end = Date(timeIntervalSince1970: summary.finishTime ?? summary.startTime ?? 0)
        let failureMessageDetails = failureMessageDetailsByTestIdentifier()

        let summaries = mapPlanRunSummaries(
            from: tests,
            fallbackName: summary.title
        )

        let failureSummaries = summary.testFailures.map { failure in
            let matchingFailureMessage = bestFailureMessage(
                for: failure,
                in: failureMessageDetails[failure.testIdentifierString] ?? []
            )
            return JunitFailureSummary(
                message: failure.failureText,
                testCaseName: failure.testIdentifierString.replacingOccurrences(of: "/", with: "."),
                issueType: "Uncategorized",
                producingTarget: nil,
                documentLocation: matchingFailureMessage?.documentLocation
            )
        }

        return [
            JunitTestAction(
                startedTime: start,
                endedTime: end,
                testPlanRunSummaries: summaries,
                failureSummaries: failureSummaries
            )
        ]
    }

    private func mapPlanRunSummaries(from tests: XCTests, fallbackName: String?) -> [JunitTestPlanRunSummary] {
        let configuredNodes = tests.testPlanConfigurations.map { config in
            (
                name: config.configurationName,
                nodes: nodes(for: config, in: tests.testNodes)
            )
        }

        if !configuredNodes.isEmpty {
            return configuredNodes.map { entry in
                JunitTestPlanRunSummary(
                    name: entry.name,
                    testableSummaries: [
                        JunitTestableSummary(
                            tests: entry.nodes.compactMap {
                                mapGroup(node: $0, parentPath: nil, currentTestClassName: nil)
                            }
                        )
                    ]
                )
            }
        }

        return [
            JunitTestPlanRunSummary(
                name: fallbackName,
                testableSummaries: [
                    JunitTestableSummary(
                        tests: tests.testNodes.compactMap {
                            mapGroup(node: $0, parentPath: nil, currentTestClassName: nil)
                        }
                    )
                ]
            )
        ]
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

        let children = node.children ?? []
        return children.flatMap { findConfigurationChildren(in: $0, configuration: configuration) }
    }

    private func mapGroup(
        node: XCTestNode,
        parentPath: String?,
        currentTestClassName: String?
    ) -> JunitTestGroup? {
        guard node.nodeType != .testCase else {
            return nil
        }

        let groupName = mappedGroupName(for: node)
        let currentPath = appendName(groupName, to: parentPath)
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
                JunitTest(
                    identifier: mappedArgumentTest.identifier,
                    name: mappedArgumentTest.name,
                    duration: mappedArgumentTest.duration,
                    isFailed: mappedArgumentTest.result == .failed,
                    isSkipped: mappedArgumentTest.result == .skipped
                )
            }
        )

        let groups = children.compactMap { child in
            mapGroup(
                node: child,
                parentPath: currentPath,
                currentTestClassName: nextTestClassName
            )
        }

        let duration = node.durationInSeconds ?? tests.compactMap(\.duration).reduce(0, +) + groups.reduce(0) { $0 + $1.duration }
        return JunitTestGroup(
            identifier: mappedGroupIdentifier(for: node, fallback: groupName),
            name: groupName,
            duration: duration,
            subtests: tests,
            subtestGroups: groups
        )
    }

    private func mapTest(node: XCTestNode, testClassName: String?) -> JunitTest {
        let result = node.result ?? .unknown
        let identifier: String = if let testClassName {
            "\(testClassName)/\(node.name)"
        } else {
            node.name
        }
        return JunitTest(
            identifier: identifier,
            name: node.name,
            duration: node.durationInSeconds,
            isFailed: result == .failed,
            isSkipped: result == .skipped
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

    private func mappedGroupIdentifier(for node: XCTestNode, fallback: String) -> String {
        switch node.nodeType {
        case .unitTestBundle, .uiTestBundle:
            return node.name.hasSuffix(".xctest") ? node.name : "\(node.name).xctest"
        case .testSuite:
            return node.name
        default:
            return node.nodeIdentifier ?? fallback
        }
    }

    private func appendName(_ name: String, to parentPath: String?) -> String {
        guard let parentPath, !parentPath.isEmpty else {
            return name
        }
        return "\(parentPath)/\(name)"
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
        var currentClassName = currentTestClassName
        if node.nodeType == .testSuite {
            currentClassName = node.name
        }
        if node.nodeType == .testCase {
            currentIdentifier = testIdentifierString(for: node, testClassName: currentClassName)
        }

        if node.nodeType == .failureMessage,
           let currentIdentifier,
           let detail = FailureMessageDetail(from: node.name) {
            result[currentIdentifier, default: []].append(detail)
        }

        for child in node.children ?? [] {
            collectFailureMessages(
                in: child,
                currentTestIdentifier: currentIdentifier,
                currentTestClassName: currentClassName,
                into: &result
            )
        }
    }

    private func testIdentifierString(for node: XCTestNode, testClassName: String?) -> String {
        if let testClassName, !testClassName.isEmpty {
            return "\(testClassName)/\(node.name)"
        }
        return node.name
    }

    private func bestFailureMessage(
        for failure: XCTestFailure,
        in candidates: [FailureMessageDetail]
    ) -> FailureMessageDetail? {
        candidates.first {
            $0.message == failure.failureText ||
                $0.message.contains(failure.failureText) ||
                failure.failureText.contains($0.message)
        } ?? candidates.first
    }

    var sessionLevelFailures: [JunitFailureSummary] {
        // Collect all test identifiers from the test nodes
        let allTestIdentifiers = collectAllTestIdentifiers(from: tests.testNodes)

        // Find failures that don't match any actual test case
        let unmatchedFailures = summary.testFailures.filter { failure in
            let normalizedIdentifier = failure.testIdentifierString.replacingOccurrences(of: "/", with: ".")
            return !allTestIdentifiers.contains(failure.testIdentifierString) &&
                   !allTestIdentifiers.contains(normalizedIdentifier)
        }

        let failureMessageDetails = failureMessageDetailsByTestIdentifier()

        return unmatchedFailures.map { failure in
            let matchingFailureMessage = bestFailureMessage(
                for: failure,
                in: failureMessageDetails[failure.testIdentifierString] ?? []
            )
            return JunitFailureSummary(
                message: failure.failureText,
                testCaseName: failure.testName,
                issueType: "Session-level failure",
                producingTarget: failure.targetName,
                documentLocation: matchingFailureMessage?.documentLocation ?? extractLocation(from: failure.testIdentifierURL)
            )
        }
    }

    private func collectAllTestIdentifiers(from nodes: [XCTestNode]) -> Set<String> {
        let identifiers = collectTestIdentifiers(from: nodes, testClassName: nil)
        return Set(identifiers)
    }

    private func collectTestIdentifiers(
        from nodes: [XCTestNode],
        testClassName: String?
    ) -> [String] {
        var identifiers = [String]()
        for node in nodes {
            var currentClassName = testClassName
            if node.nodeType == .testSuite {
                currentClassName = node.name
            }
            if node.nodeType == .testCase {
                let identifier = testIdentifierString(for: node, testClassName: currentClassName)
                // Skip the synthetic "Issues recorded without an associated test or suite" node
                // This represents session-level failures and should be handled separately
                if !isSessionLevelFailureIdentifier(identifier) {
                    identifiers.append(identifier)
                }
            }
            if let children = node.children {
                // recurse
                identifiers.append(
                    contentsOf: collectTestIdentifiers(
                        from: children,
                        testClassName: currentClassName
                    )
                )
            }
        }
        return identifiers
    }

    private func extractLocation(from url: URL?) -> String? {
        guard let url else { return nil }
        // testIdentifierURL format: "test://com.apple.xcode/Xcresultparser/XcresultparserTests/XcresultparserTests/testName"
        // We want to extract the path components to form a file location hint
        let pathComponents = url.pathComponents.filter { !$0.isEmpty && $0 != "/" }
        guard pathComponents.count >= 2 else { return nil }
        // Try to form a meaningful path like "XcresultparserTests/testName"
        return pathComponents.suffix(2).joined(separator: "/")
    }

    private func isSessionLevelFailureIdentifier(_ identifier: String) -> Bool {
        // Swift Testing creates synthetic test nodes for session-level failures
        identifier == "Issues recorded without an associated test or suite" ||
        identifier.contains("«unknown»")
    }
}

