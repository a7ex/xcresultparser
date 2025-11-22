//
//  XCTestResult.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

enum XCTestResult: String, Codable {
    case passed = "Passed"
    case failed = "Failed"
    case skipped = "Skipped"
    case expectedFailure = "Expected Failure"
    case unknown = "unknown"
}
