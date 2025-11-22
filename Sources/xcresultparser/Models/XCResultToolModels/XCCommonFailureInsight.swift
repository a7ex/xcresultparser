//
//  XCCommonFailureInsight.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCCommonFailureInsight: Codable {
    let failuresCount: Int
    let impact: String
    let description: String
    let associatedTestIdentifiers: [String]
}

