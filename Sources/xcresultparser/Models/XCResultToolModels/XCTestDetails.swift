//
//  XCTestDetails.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//
// xcrun xcresulttool get test-results test-details

struct XCTestDetails: Codable {
    let testIdentifier: String
    let testName: String
    let testDescription: String
    let duration: String
    let testPlanConfigurations: [XCConfiguration]
    let devices: [XCDevice]
    let testRuns: [XCTestNode]
    let testResult: XCTestResult
    let hasPerformanceMetrics: Bool
    let hasMediaAttachments: Bool

    // Human-readable duration with optional components of days, hours, minutes and seconds
    let testIdentifierURL: String?
    // Time interval in seconds
    let durationInSeconds: Double?
    // Date as a UNIX timestamp (seconds since midnight UTC on January 1, 1970)
    let startTime: Double?
    let arguments: [XCArgument]
    let tags: [String]
    let bugs: [XCBug]
    let functionName: String?
}

extension XCTestDetails {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        testIdentifier = try values.decode(String.self, forKey: .testIdentifier)
        testName = try values.decode(String.self, forKey: .testName)
        testDescription = try values.decode(String.self, forKey: .testDescription)
        duration = try values.decode(String.self, forKey: .duration)
        testPlanConfigurations = try values.decode([XCConfiguration].self, forKey: .testPlanConfigurations)
        devices = try values.decode([XCDevice].self, forKey: .devices)
        testRuns = try values.decode([XCTestNode].self, forKey: .testRuns)
        testResult = try values.decode(XCTestResult.self, forKey: .testResult)
        if let performanceFlag = try? values.decode(Bool.self, forKey: .hasPerformanceMetrics) {
            hasPerformanceMetrics = performanceFlag
        } else {
            hasPerformanceMetrics = (try? values.decode(String.self, forKey: .hasPerformanceMetrics)) == "true"
        }
        if let mediaFlag = try? values.decode(Bool.self, forKey: .hasMediaAttachments) {
            hasMediaAttachments = mediaFlag
        } else {
            hasMediaAttachments = (try? values.decode(String.self, forKey: .hasMediaAttachments)) == "true"
        }
        testIdentifierURL = try? values.decode(String.self, forKey: .testIdentifierURL)
        durationInSeconds = try? values.decode(Double.self, forKey: .durationInSeconds)
        startTime = try? values.decode(Double.self, forKey: .startTime)
        arguments = (try? values.decode([XCArgument].self, forKey: .arguments)) ?? []
        tags = (try? values.decode([String].self, forKey: .tags)) ?? []
        bugs = (try? values.decode([XCBug].self, forKey: .bugs)) ?? []
        functionName = try? values.decode(String.self, forKey: .functionName)
    }
}
