//
//  XCMetric.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results metrics

struct XCMetric: Codable {
    let displayName: String
    let unitOfMeasurement: String
    let measurements: [Double]
    let identifier: String?
    let baselineName: String?
    let baselineAverage: Double?
    let maxRegression: Double?
    let maxPercentRegression: Double?
    let maxStandardDeviation: Double?
    let maxPercentRelativeStandardDeviation: Double?
    let polarity: String?
}
