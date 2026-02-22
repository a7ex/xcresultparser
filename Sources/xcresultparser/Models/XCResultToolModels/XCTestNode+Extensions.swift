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
    }

    func mapArgumentTest(argument: XCTestNode, testClassName: String?) -> MappedArgumentTest {
        let baseIdentifier: String
        if let testClassName {
            baseIdentifier = "\(testClassName)/\(name)"
        } else {
            baseIdentifier = name
        }
        return MappedArgumentTest(
            identifier: baseIdentifier.formatWithParameter(argument.name),
            name: name.formatWithParameter(argument.name),
            duration: argument.durationInSeconds ?? durationInSeconds,
            result: argument.result ?? result ?? .unknown
        )
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

        let signature = String(self[index(after: openParenIndex)..<closeParenIndex])
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

            if character == "," && !isInQuotes {
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
