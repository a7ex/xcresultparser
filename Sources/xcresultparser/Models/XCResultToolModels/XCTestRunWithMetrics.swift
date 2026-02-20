//
//  XCTestRunWithMetrics.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results metrics

struct XCTestRunWithMetrics: Codable {
    let testPlanConfiguration: XCConfiguration
    let device: XCDevice
    let metrics: [XCMetric]
}
