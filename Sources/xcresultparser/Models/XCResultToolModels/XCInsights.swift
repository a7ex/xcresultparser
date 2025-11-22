//
//  XCInsights.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCInsights: Codable {
    let commonFailureInsights: XCCommonFailureInsight
    let longestTestRunsInsights: XCLongestTestRunsInsight
    let failureDistributionInsights: XCFailureDistributionInsight
}
