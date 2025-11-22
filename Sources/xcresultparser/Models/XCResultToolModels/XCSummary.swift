//
//  XCSummary.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCSummary: Codable {
    let title: String
    // Description of the Test Plan, OS, and environment that was used during testing
    let environmentDescription: String
    let topInsights: [XCInsightSummary]
    let result: XCTestResult
    let totalTestCount: Int
    let passedTests: Int
    let failedTests: Int
    let skippedTests: Int
    let expectedFailures: Int
    let statistics: [XCStatistic]
    let devicesAndConfigurations: XCDeviceAndConfigurationSummary
    let testFailures: XCTestFailure

    // Optional:
    // Date as a UNIX timestamp (seconds since midnight UTC on January 1, 1970)
    let startTime: Double
    // Date as a UNIX timestamp (seconds since midnight UTC on January 1, 1970)
    let finishTime: Double
}

extension XCSummary {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        environmentDescription = try values.decode(String.self, forKey: .environmentDescription)
        topInsights = try values.decode([XCInsightSummary].self, forKey: .topInsights)
        result = try values.decode(XCTestResult.self, forKey: .result)
        totalTestCount = try values.decode(Int.self, forKey: .totalTestCount)
        passedTests = try values.decode(Int.self, forKey: .passedTests)
        failedTests = try values.decode(Int.self, forKey: .failedTests)
        skippedTests = try values.decode(Int.self, forKey: .skippedTests)
        expectedFailures = try values.decode(Int.self, forKey: .expectedFailures)
        statistics = try values.decode([XCStatistic].self, forKey: .statistics)
        devicesAndConfigurations = try values.decode(XCDeviceAndConfigurationSummary.self, forKey: .devicesAndConfigurations)
        testFailures = try values.decode(XCTestFailure.self, forKey: .testFailures)
        startTime = (try? values.decode(Double.self, forKey: .startTime)) ?? 0
        finishTime = (try? values.decode(Double.self, forKey: .finishTime)) ?? 0
    }
}
