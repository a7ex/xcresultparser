//
//  XCLongestTestRunsInsight.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCLongestTestRunsInsight: Codable {
    let title: String
    let impact: String
    let associatedTestIdentifiers: [String]
    let targetName: String
    let testPlanConfigurationName: String
    let deviceName: String
    let osNameAndVersion: String
    let durationOfSlowTests: Double
    let meanTime: String
}

