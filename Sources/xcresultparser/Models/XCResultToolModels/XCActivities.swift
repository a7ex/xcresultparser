//
//  XCActivities.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results activities

struct XCActivities: Codable {
    let testIdentifier: String
    let testName: String
    let testRuns: [XCTestRunActivities]
    let testIdentifierURL: String?
}
