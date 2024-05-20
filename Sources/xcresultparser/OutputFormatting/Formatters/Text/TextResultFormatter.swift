//
//  TextResultFormatter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 03.06.21.
//

import Foundation

public struct TextResultFormatter: XCResultFormatting {
    private let indentWidth = "  "

    public init() {}

    public func documentPrefix(title: String) -> String {
        return ""
    }

    public var documentSuffix: String {
        return ""
    }

    public var accordionOpenTag: String {
        return ""
    }

    public var accordionCloseTag: String {
        return ""
    }

    public var tableOpenTag: String {
        return ""
    }

    public var tableCloseTag: String {
        return ""
    }

    public var divider: String {
        return "---------------------\n"
    }

    public func resultSummaryLine(_ item: String, failed: Bool) -> String {
        return indentWidth + item
    }

    public func resultSummaryLineWarning(_ item: String, hasWarnings: Bool) -> String {
        return indentWidth + item
    }

    public func testConfiguration(_ item: String) -> String {
        return item
    }

    public func testTarget(_ item: String, failed: Bool) -> String {
        return indentWidth + item
    }

    public func testClass(_ item: String, failed: Bool) -> String {
        return String(repeating: indentWidth, count: 2) + item
    }

    public func singleTestItem(_ item: String, failed: Bool) -> String {
        return String(repeating: indentWidth, count: 3) + item
    }

    public func failedTestItem(_ item: String, message: String) -> String {
        return String(repeating: indentWidth, count: 3) + item + "\n" +
            String(repeating: indentWidth, count: 4) + message
    }

    public func codeCoverageTargetSummary(_ item: String) -> String {
        return item
    }

    public func codeCoverageFileSummary(_ item: String) -> String {
        return indentWidth + item
    }

    public func codeCoverageFunctionSummary(_ items: [String]) -> String {
        return indentWidth + indentWidth + items.joined(separator: " ")
    }
}
