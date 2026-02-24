//
//  XCTests.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results tests

struct XCTests: Codable {
    let testPlanConfigurations: [XCConfiguration]
    let devices: [XCDevice]
    let testNodes: [XCTestNode]
}
