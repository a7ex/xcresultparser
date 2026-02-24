//
//  XCTestNodeType.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//
// xcrun xcresulttool get test-results tests

enum XCTestNodeType: String, Codable {
    case testPlan = "Test Plan"
    case testPlanConfiguration = "Test Plan Configuration"
    case unitTestBundle = "Unit test bundle"
    case uiTestBundle = "UI test bundle"
    case testSuite = "Test Suite"
    case testCase = "Test Case"
    case arguments = "Arguments"
    case repetition = "Repetition"
    case failureMessage = "Failure Message"
    case device = "Device"
    case testCaseRun = "Test Case Run"
    case sourceCodeReference = "Source Code Reference"
    case attachment = "Attachment"
    case expression = "Expression"
    case testValue = "Test Value"
    case runtimeWarning = "Runtime Warning"
    case unknown
}

extension XCTestNodeType {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = XCTestNodeType(rawValue: value) ?? .unknown
    }
}
