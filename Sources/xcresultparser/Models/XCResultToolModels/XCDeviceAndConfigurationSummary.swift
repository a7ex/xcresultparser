//
//  XCDeviceAndConfigurationSummary.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCDeviceAndConfigurationSummary: Codable {
    let device: XCDeviceInfo
    let testPlanConfiguration: XCTestPlanConfiguration
    let passedTests: Int
    let failedTests: Int
    let skippedTests: Int
    let expectedFailures: Int
}

