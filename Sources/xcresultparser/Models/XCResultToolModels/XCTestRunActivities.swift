//
//  XCTestRunActivities.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results activities

struct XCTestRunActivities: Codable {
    let device: String
    let testPlanConfiguration: String
    let activities: [XCActivityNode]
    let arguments: [XCArgument]?
}
