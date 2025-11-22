//
//  XCTestDetails.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCTestDetails: Codable {
    let testIdentifier: String
    let testName: String
    let testDescription: String
    let duration: String
    let testPlanConfigurations: [XCTestPlanConfiguration]
    let devices: [XCDeviceInfo]
    let testRuns: String
    let testResult: String
    let hasPerformanceMetrics: String
    let hasMediaAttachments: String

    // Human-readable duration with optional components of days, hours, minutes and seconds
    let testIdentifierURL: String?
    // Time interval in seconds
    let durationInSeconds: Double?
    // Date as a UNIX timestamp (seconds since midnight UTC on January 1, 1970)
    let startTime: Double?
    let arguments: []
}
