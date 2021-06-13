//
//  TextResultFormatter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 03.06.21.
//

import Foundation

struct TextResultFormatter: XCResultFormatting {
    private let indentWidth = "  "
    
    func documentPrefix(title: String) -> String {
        return ""
    }
    var documentSuffix: String {
        return ""
    }
    var accordionOpenTag: String {
        return ""
    }
    var accordionCloseTag: String {
        return ""
    }
    var tableOpenTag: String {
        return ""
    }
    var tableCloseTag: String {
        return ""
    }
    var divider: String {
        return "---------------------\n"
    }
    func resultSummaryLine(_ item: String, failed: Bool) -> String {
        return indentWidth + item
    }
    func resultSummaryLineWarning(_ item: String, hasWarnings: Bool) -> String {
        return indentWidth + item
    }
    func testConfiguration(_ item: String) -> String {
        return item
    }
    func testTarget(_ item: String, failed: Bool) -> String {
        return indentWidth + item
    }
    func testClass(_ item: String, failed: Bool) -> String {
        return String(repeating: indentWidth, count: 2) + item
    }
    func singleTestItem(_ item: String, failed: Bool) -> String {
        return String(repeating: indentWidth, count: 3) + item
    }
    func failedTestItem(_ item: String, message: String) -> String {
        return String(repeating: indentWidth, count: 3) + item + "\n" +
            String(repeating: indentWidth, count: 4) + message
    }
    func codeCoverageTargetSummary(_ item: String) -> String {
        return item
    }
    func codeCoverageFileSummary(_ item: String) -> String {
        return indentWidth + item
    }
    func codeCoverageFunctionSummary(_ items: [String]) -> String {
        return indentWidth + indentWidth + items.joined(separator: " ")
    }
}
