//
//  CLIResultFormatter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 02.06.21.
//

import Foundation

struct CLIResultFormatter: XCResultFormatting {
    private let style = CLIFormat()
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
        return "-----------------\n"
    }
    func resultSummaryLine(_ item: String, failed: Bool) -> String {
        return color(for: failed) + indentWidth + item + style.reset
    }
    func resultSummaryLineWarning(_ item: String, hasWarnings: Bool) -> String {
        return warningColor(for: hasWarnings) + indentWidth + item + style.reset
    }
    func testConfiguration(_ item: String) -> String {
        return style.bold + item + style.reset
    }
    func testTarget(_ item: String, failed: Bool) -> String {
        return color(for: failed) + indentWidth + item + style.reset
    }
    func testClass(_ item: String, failed: Bool) -> String {
        return color(for: failed) + String(repeating: indentWidth, count: 2) + item + style.reset
    }
    func singleTestItem(_ item: String, failed: Bool) -> String {
        return singleItemColor(for: failed) + String(repeating: indentWidth, count: 3) + item + style.reset
    }
    func failedTestItem(_ item: String, message: String) -> String {
        return singleItemColor(for: true) + String(repeating: indentWidth, count: 3) + item + "\n" +
            String(repeating: indentWidth, count: 4) + message + style.reset
    }
    func codeCoverageTargetSummary(_ item: String) -> String {
        return indentWidth + style.bold + item + style.reset
    }
    func codeCoverageFileSummary(_ item: String) -> String {
        return String(repeating: indentWidth, count: 2) + item
    }
    func codeCoverageFunctionSummary(_ items: [String]) -> String {
        return String(repeating: indentWidth, count: 3) + items.joined(separator: " ")
    }
    
    // MARK: - Private
    
    // Red <-> Black
    private func color(for failure: Bool) -> String {
        return failure ? style.red: ""
    }
    // Yellow <-> Black
    private func warningColor(for failure: Bool) -> String {
        return failure ? style.yellow: ""
    }
    // Red <-> Green
    private func singleItemColor(for failure: Bool) -> String {
        return failure ? style.red: style.green
    }
}
