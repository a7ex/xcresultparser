//
//  XCTestNode+Extensions.swift
//  xcresultparser
//

import Foundation

extension XCTestNode {
    struct MappedArgumentTest {
        let identifier: String
        let name: String
        let duration: TimeInterval?
        let result: XCTestResult
        let isFlaky: Bool
    }

    func mapArgumentTest(argument: XCTestNode, testClassName: String?) -> MappedArgumentTest {
        let fallbackIdentifier: String = if let testClassName {
            "\(testClassName)/\(name)"
        } else {
            name
        }
        let baseIdentifier = nodeIdentifier ?? fallbackIdentifier
        return MappedArgumentTest(
            identifier: baseIdentifier.formatWithParameter(argument.name),
            name: name.formatWithParameter(argument.name),
            duration: argument.durationInSeconds ?? durationInSeconds,
            result: argument.result ?? result ?? .unknown,
            isFlaky: argument.isFlaky
        )
    }

    /// The results of all `Repetition` nodes nested below this node.
    ///
    /// Descends through intermediate nodes (e.g. `Test Case Run` for per-device
    /// runs) so that repetitions are found regardless of how deeply Xcode nests
    /// them under a test case or an argument.
    var repetitionResults: [XCTestResult] {
        (children ?? []).flatMap { child -> [XCTestResult] in
            child.nodeType == .repetition
                ? [child.result ?? .unknown]
                : child.repetitionResults
        }
    }

    /// `true` when the test was retried and recovered: at least one repetition
    /// passed while at least one other repetition failed. Such a test is
    /// "flaky"/"mixed" rather than a clean pass or a clean failure.
    var isFlaky: Bool {
        let results = repetitionResults
        return results.contains(.passed) && results.contains(.failed)
    }
}

extension [XCTestNode] {
    func mapTests<TestType>(
        testClassName: String?,
        mapTest: (XCTestNode, String?) -> TestType,
        mapArgumentTest: (XCTestNode.MappedArgumentTest) -> TestType
    ) -> [TestType] {
        var tests = [TestType]()
        for node in self where node.nodeType == .testCase {
            let argumentNodes = (node.children ?? []).filter { $0.nodeType == .arguments }
            if argumentNodes.isEmpty {
                tests.append(mapTest(node, testClassName))
            } else {
                for argument in argumentNodes {
                    tests.append(mapArgumentTest(node.mapArgumentTest(argument: argument, testClassName: testClassName)))
                }
            }
        }
        return tests
    }
}

private extension String {
    func formatWithParameter(_ parameterValue: String) -> String {
        guard let openParenIndex = firstIndex(of: "("),
              let closeParenIndex = lastIndex(of: ")"),
              openParenIndex < closeParenIndex else {
            return "\(self) [\(parameterValue)]"
        }

        let signature = String(self[index(after: openParenIndex) ..< closeParenIndex])
        let labels = parameterLabels(from: signature)
        guard !labels.isEmpty else {
            return "\(self) [\(parameterValue)]"
        }

        let values = splitValues(parameterValue)
        let parameterized: String
        if labels.count == values.count {
            parameterized = zip(labels, values)
                .map { "\($0): \($1)" }
                .joined(separator: ", ")
        } else if labels.count == 1 {
            parameterized = "\(labels[0]): \(parameterValue.trimmingCharacters(in: .whitespacesAndNewlines))"
        } else {
            return "\(self) [\(parameterValue)]"
        }

        return "\(self[..<openParenIndex])(\(parameterized))"
    }

    private func parameterLabels(from signature: String) -> [String] {
        var labels = [String]()
        var token = ""

        for character in signature {
            if character == "," {
                token = ""
                continue
            }
            if character == ":" {
                let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
                if let label = trimmed.split(whereSeparator: \.isWhitespace).last, !label.isEmpty {
                    labels.append(String(label))
                }
                token = ""
                continue
            }
            token.append(character)
        }

        return labels
    }

    private func splitValues(_ raw: String) -> [String] {
        var values = [String]()
        var current = ""
        var isInQuotes = false

        for character in raw {
            if character == "\"" {
                isInQuotes.toggle()
                current.append(character)
                continue
            }

            if character == ",", !isInQuotes {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    values.append(trimmed)
                }
                current = ""
                continue
            }

            current.append(character)
        }

        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            values.append(trimmed)
        }

        return values
    }
}
