//
//  XCInsights.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//
// xcrun xcresulttool get test-results insights

struct XCInsights: Codable {
    let commonFailureInsights: XCCommonFailureInsight
    let longestTestRunsInsights: XCLongestTestRunsInsight
    let failureDistributionInsights: XCFailureDistributionInsight
}
