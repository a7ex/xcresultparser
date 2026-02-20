//
//  XCTestRunActivities.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results activities

struct XCTestRunActivities: Codable {
    let device: XCDevice
    let testPlanConfiguration: XCConfiguration
    let activities: [XCActivityNode]
    let arguments: [XCArgument]?
}
