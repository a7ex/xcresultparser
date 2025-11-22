//
//  XCFailureDistributionInsight.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCFailureDistributionInsight: Codable {
    let title: String
    let impact: String
    let distributionPercent: Double
    let associatedTestIdentifiers: [String]

    // Optional
    let bug: String?
    let tag: String?
    let destinations: [String]?
}

