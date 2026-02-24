//
//  XCInsights.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//
// xcrun xcresulttool get test-results insights

struct XCInsights: Codable {
    let commonFailureInsights: [XCCommonFailureInsight]
    let longestTestRunsInsights: [XCLongestTestRunsInsight]
    let failureDistributionInsights: [XCFailureDistributionInsight]
}

extension XCInsights {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        commonFailureInsights = (try? values.decode([XCCommonFailureInsight].self, forKey: .commonFailureInsights)) ?? []
        longestTestRunsInsights = (try? values.decode([XCLongestTestRunsInsight].self, forKey: .longestTestRunsInsights)) ?? []
        failureDistributionInsights = (try? values.decode([XCFailureDistributionInsight].self, forKey: .failureDistributionInsights)) ?? []
    }
}
