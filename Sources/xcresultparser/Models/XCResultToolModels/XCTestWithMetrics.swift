//
//  XCTestWithMetrics.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results metrics

struct XCTestWithMetrics: Codable {
    let testIdentifier: String
    let testRuns: [XCTestRunWithMetrics]
    let testIdentifierURL: String?
}
