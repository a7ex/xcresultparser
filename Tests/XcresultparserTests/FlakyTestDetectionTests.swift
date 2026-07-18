import Foundation
@testable import XcresultparserLib
import Testing

// Tests for detecting "flaky"/"mixed" tests: a test that failed on a first
// attempt but passed on retry. The per-repetition results live in the
// xcresult test tree as `Repetition` children of a `Test Case` (or, for
// parameterized tests, of an `Arguments` node), and may be nested below a
// `Test Case Run` for per-device runs.
struct FlakyTestDetectionTests {
    private func node(from json: String) throws -> XCTestNode {
        try JSONDecoder().decode(XCTestNode.self, from: Data(json.utf8))
    }

    @Test
    func mixedRepetitionsAreFlaky() throws {
        let testCase = try node(from: """
        {
          "name": "test_random()",
          "nodeType": "Test Case",
          "result": "Failed",
          "children": [
            { "name": "Repetition 1", "nodeType": "Repetition", "result": "Failed" },
            { "name": "Repetition 2", "nodeType": "Repetition", "result": "Passed" }
          ]
        }
        """)

        #expect(testCase.isFlaky)
        #expect(testCase.repetitionResults == [.failed, .passed])
    }

    @Test
    func allFailedRepetitionsAreNotFlaky() throws {
        let testCase = try node(from: """
        {
          "name": "test_random()",
          "nodeType": "Test Case",
          "result": "Failed",
          "children": [
            { "name": "Repetition 1", "nodeType": "Repetition", "result": "Failed" },
            { "name": "Repetition 2", "nodeType": "Repetition", "result": "Failed" },
            { "name": "Repetition 3", "nodeType": "Repetition", "result": "Failed" }
          ]
        }
        """)

        #expect(!testCase.isFlaky)
    }

    @Test
    func allPassedRepetitionsAreNotFlaky() throws {
        let testCase = try node(from: """
        {
          "name": "test_random()",
          "nodeType": "Test Case",
          "result": "Passed",
          "children": [
            { "name": "Repetition 1", "nodeType": "Repetition", "result": "Passed" },
            { "name": "Repetition 2", "nodeType": "Repetition", "result": "Passed" }
          ]
        }
        """)

        #expect(!testCase.isFlaky)
    }

    @Test
    func testCaseWithoutRepetitionsIsNotFlaky() throws {
        let testCase = try node(from: """
        {
          "name": "test_simple()",
          "nodeType": "Test Case",
          "result": "Passed"
        }
        """)

        #expect(!testCase.isFlaky)
        #expect(testCase.repetitionResults.isEmpty)
    }

    @Test
    func repetitionsNestedUnderTestCaseRunAreDetected() throws {
        // Per-device runs wrap the repetitions in a "Test Case Run" node.
        let testCase = try node(from: """
        {
          "name": "test_random()",
          "nodeType": "Test Case",
          "result": "Failed",
          "children": [
            {
              "name": "iPhone 16 Pro",
              "nodeType": "Test Case Run",
              "children": [
                { "name": "Repetition 1", "nodeType": "Repetition", "result": "Failed" },
                { "name": "Repetition 2", "nodeType": "Repetition", "result": "Passed" }
              ]
            }
          ]
        }
        """)

        #expect(testCase.isFlaky)
    }

    @Test
    func parameterizedArgumentWithMixedRepetitionsIsFlaky() throws {
        // For parameterized tests the repetitions hang off the "Arguments" node.
        let testCase = try node(from: """
        {
          "name": "test_value(input:)",
          "nodeType": "Test Case",
          "result": "Failed",
          "children": [
            {
              "name": "42",
              "nodeType": "Arguments",
              "result": "Failed",
              "children": [
                { "name": "Repetition 1", "nodeType": "Repetition", "result": "Failed" },
                { "name": "Repetition 2", "nodeType": "Repetition", "result": "Passed" }
              ]
            }
          ]
        }
        """)

        let argumentsNode = try #require(testCase.children?.first)
        let mapped = testCase.mapArgumentTest(argument: argumentsNode, testClassName: "MySuite")

        #expect(mapped.isFlaky)
        #expect(mapped.result == .failed)
    }

    @Test
    func parameterizedArgumentWithAllFailedRepetitionsIsNotFlaky() throws {
        let testCase = try node(from: """
        {
          "name": "test_value(input:)",
          "nodeType": "Test Case",
          "result": "Failed",
          "children": [
            {
              "name": "42",
              "nodeType": "Arguments",
              "result": "Failed",
              "children": [
                { "name": "Repetition 1", "nodeType": "Repetition", "result": "Failed" },
                { "name": "Repetition 2", "nodeType": "Repetition", "result": "Failed" }
              ]
            }
          ]
        }
        """)

        let argumentsNode = try #require(testCase.children?.first)
        let mapped = testCase.mapArgumentTest(argument: argumentsNode, testClassName: "MySuite")

        #expect(!mapped.isFlaky)
    }
}
