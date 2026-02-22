//
//  XCDeviceAndConfigurationSummary.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//
// xcrun xcresulttool get test-results summary

struct XCDeviceAndConfigurationSummary: Codable {
    let device: XCDevice
    let testPlanConfiguration: XCConfiguration
    let passedTests: Int
    let failedTests: Int
    let skippedTests: Int
    let expectedFailures: Int
}
