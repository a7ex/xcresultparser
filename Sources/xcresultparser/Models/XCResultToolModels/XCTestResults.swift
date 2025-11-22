//
//  XCTestResults.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//


struct XCTestResults: Codable {
    let devices: [XCDeviceInfo]
    let testNodes: [XCTestNode]
    let testPlanConfigurations: [XCTestPlanConfiguration]
}
