//
//  XCResultFormatting.swift
//  xcresult2text
//
//  Created by Alex da Franca on 02.06.21.
//

import Foundation

public protocol XCResultFormatting {
    func documentPrefix(title: String) -> String
    var documentSuffix: String { get }
    var divider: String { get }

    var accordionOpenTag: String { get }
    var accordionCloseTag: String { get }
    var tableOpenTag: String { get }
    var tableCloseTag: String { get }

    func resultSummaryLine(_ item: String, failed: Bool) -> String
    func resultSummaryLineWarning(_ item: String, hasWarnings: Bool) -> String
    func testConfiguration(_ item: String) -> String
    func testTarget(_ item: String, failed: Bool) -> String
    func testClass(_ item: String, failed: Bool) -> String
    func singleTestItem(_ item: String, failed: Bool) -> String
    func failedTestItem(_ item: String, message: String) -> String
    var testFailIcon: String { get }
    var testPassIcon: String { get }
    var testSkipIcon: String { get }

    func codeCoverageTargetSummary(_ item: String) -> String
    func codeCoverageFileSummary(_ item: String) -> String
    func codeCoverageFunctionSummary(_ items: [String]) -> String
}

public extension XCResultFormatting {
    var testFailIcon: String {
        return "✖︎"
    }

    var testPassIcon: String {
        return "✓"
    }

    var testSkipIcon: String {
        return "-"
    }
}
