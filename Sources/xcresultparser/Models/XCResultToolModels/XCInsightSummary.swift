//
//  XCInsightSummary.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//
// xcrun xcresulttool get test-results summary

struct XCInsightSummary: Codable {
    let impact: String
    let category: String
    let text: String
}
