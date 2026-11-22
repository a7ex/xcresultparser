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
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        testIdentifier = try values.decode(String.self, forKey: .testIdentifier)
        testName = try values.decode(String.self, forKey: .testName)
        testDescription = try values.decode(String.self, forKey: .testDescription)
        duration = try values.decode(String.self, forKey: .duration)
        testPlanConfigurations = try values.decode([XCConfiguration].self, forKey: .testPlanConfigurations)
        devices = try values.decode([XCDevice].self, forKey: .devices)
        testRuns = try values.decode([XCTestNode].self, forKey: .testRuns)
        testResult = try values.decode(XCTestResult.self, forKey: .testResult)
        hasPerformanceMetrics = if let performanceFlag = try? values.decodeIfPresent(Bool.self, forKey: .hasPerformanceMetrics) {
            performanceFlag
        } else {
            (try? values.decodeIfPresent(String.self, forKey: .hasPerformanceMetrics)) == "true"
        }
        hasMediaAttachments = if let mediaFlag = try? values.decodeIfPresent(Bool.self, forKey: .hasMediaAttachments) {
            mediaFlag
        } else {
            (try? values.decodeIfPresent(String.self, forKey: .hasMediaAttachments)) == "true"
        }
        testIdentifierURL = try? values.decodeIfPresent(String.self, forKey: .testIdentifierURL)
        durationInSeconds = try? values.decodeIfPresent(Double.self, forKey: .durationInSeconds)
        startTime = try? values.decodeIfPresent(Double.self, forKey: .startTime)
        arguments = (try? values.decodeIfPresent([XCArgument].self, forKey: .arguments)) ?? []
        tags = (try? values.decodeIfPresent([String].self, forKey: .tags)) ?? []
        bugs = (try? values.decodeIfPresent([XCBug].self, forKey: .bugs)) ?? []
        functionName = try? values.decodeIfPresent(String.self, forKey: .functionName)
    }
}
