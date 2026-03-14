//
//  JunitXMLDataProviding.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 20.02.26.
//

import Foundation

protocol JunitXMLDataProviding {
    var metrics: JunitInvocationMetrics { get }
    var testActions: [JunitTestAction] { get }
    var sessionLevelFailures: [JunitFailureSummary] { get }
}

struct JunitInvocationMetrics {
    let testsCount: Int
    let testsFailedCount: Int
}

struct JunitTestAction {
    let startedTime: Date
    let endedTime: Date
    let testPlanRunSummaries: [JunitTestPlanRunSummary]
    let failureSummaries: [JunitFailureSummary]
}

struct JunitTestPlanRunSummary {
    let name: String?
    let testableSummaries: [JunitTestableSummary]
}

struct JunitTestableSummary {
    let tests: [JunitTestGroup]
}

struct JunitTestGroup {
    let identifier: String?
    let name: String?
    let duration: Double
    let subtests: [JunitTest]
    let subtestGroups: [JunitTestGroup]
}

struct JunitTest {
    let identifier: String?
    let name: String?
    let duration: Double?
    let isFailed: Bool
    let isSkipped: Bool
}

struct JunitFailureSummary {
    let message: String
    let testCaseName: String
    let issueType: String
    let producingTarget: String?
    let documentLocation: String?
}
