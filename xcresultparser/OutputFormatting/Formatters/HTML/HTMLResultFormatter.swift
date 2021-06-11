//
//  HTMLResultFormatter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 02.06.21.
//

import Foundation

struct HTMLResultFormatter: XCResultFormatting {
    
    func documentPrefix(title: String) -> String {
        return htmlDocStart(with: title)
    }
    var documentSuffix: String {
        return
            """
<script>
var acc = document.getElementsByClassName("accordion");
var i;

for (i = 0; i < acc.length; i++) {
  acc[i].addEventListener("click", function() {
    this.classList.toggle("active");
    var panel = this.nextElementSibling;
    if (panel.style.maxHeight) {
      panel.style.maxHeight = null;
    } else {
      panel.style.maxHeight = panel.scrollHeight + "px";
    }
  });
}
</script>
</body>\n</html>
"""
    }
    var accordionOpenTag: String {
        return "<div class=\"panel\">"
    }
    var accordionCloseTag: String {
        return "</div>"
    }
    var tableOpenTag: String {
        return "<table>"
    }
    var tableCloseTag: String {
        return "</table>"
    }
    var divider: String {
        return "<hr>"
    }
    func resultSummaryLine(_ item: String, failed: Bool) -> String {
        let cssClass = failed ? "resultSummaryLineFailed": "resultSummaryLineSuccess"
        return "<p class=\"\(cssClass)\">" + item + "</p>"
    }
    func resultSummaryLineWarning(_ item: String, failed: Bool) -> String {
        let cssClass = failed ? "resultSummaryLineWarning": "resultSummaryLineSuccess"
        return "<p class=\"\(cssClass)\">" + item + "</p>"
    }
    func testConfiguration(_ item: String) -> String {
        return "<h2>" + item + "</h2>"
    }
    func testTarget(_ item: String, failed: Bool) -> String {
        let cssClass = failed ? "testTargetFailed": "testTargetSuccess"
        return "<p class=\"\(cssClass)\">" + item + "</p>"
    }
    func testClass(_ item: String, failed: Bool) -> String {
        let cssClass = failed ? "testClassFailed": "testClassSuccess"
        return "<button class=\"accordion\"><span class=\"\(cssClass)\">\(item)</span></button>"
    }
    func singleTestItem(_ item: String, failed: Bool) -> String {
        let cssClass = failed ? "singleTestItemFailed": "singleTestItemSuccess"
        return "<p class=\"\(cssClass)\">" + item + "</p>"
    }
    func failedTestItem(_ item: String, message: String) -> String {
        let button = "<button class=\"accordion\"><span class=\"singleTestItemFailedWithMessage\">\(item)</span></button>"
        let msg = "<p class=\"singleTestItemFailedMessage\">\(message)</p>"
        return button + "\n" +
        accordionOpenTag + msg + accordionCloseTag
    }
    func codeCoverageTargetSummary(_ item: String) -> String {
        return "<button class=\"accordion\">\(item)</button>"
    }
    func codeCoverageFileSummary(_ item: String) -> String {
        return "<button class=\"accordion\">\(item)</button>"
    }
    func codeCoverageFunctionSummary(_ items: [String]) -> String {
        return "<tr><td>" + items.joined(separator: "</td><td>") + "</td></tr>"
//        return "<p class=\"codeCoverageFunctionSummary\">" + item + "</p>"
    }
    
    // MARK: - Private
    
    private func htmlDocStart(with title: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <title>\(title)</title>
            <style type='text/css'>
                .resultSummaryLineFailed {
                    color: red;
                    margin: 0 0 0 16px;
                }
                .resultSummaryLineWarning {
                    color: orange;
                    margin: 0 0 0 16px;
                }
                .resultSummaryLineSuccess {
                    margin: 0 0 0 16px;
                }
                .testTargetFailed {
                    color: red;
                    margin: 0 0 0 16px;
                    font-weight: bold;
                }
                .testTargetSuccess {
                    margin: 0 0 0 16px;
                    font-weight: bold;
                }
                .testClassFailed {
                    color: red;
                    margin: 8px 0 0 32px;
                }
                .testClassSuccess {
                    color: green;
                    margin: 8px 0 0 32px;
                }
                .singleTestItemFailed {
                    color: red;
                    margin: 0 0 8px 48px;
                }
                .singleTestItemFailedWithMessage {
                    color: red;
                    margin: 0 0 0 32px;
                }
                .singleTestItemFailedMessage {
                    color: red;
                    margin: 0 0 8px 48px;
                }
                .singleTestItemSuccess {
                    color: green;
                    margin: 0 0 8px 48px;
                }
                .codeCoverageTargetSummary {
                    margin: 0 0 0 16px;
                }
                .codeCoverageFileSummary {
                    margin: 0 0 0 32px;
                }
                .codeCoverageFunctionSummary {
                    margin: 0 0 0 48px;
                }
                .accordion {
                    background-color: #eee;
                    color: #444;
                    cursor: pointer;
                    padding: 8px 0 8px 16px;
                    width: 100%;
                    border: none;
                    text-align: left;
                    outline: none;
                    font-size: 15px;
                    transition: 0.4s;
                }
                .active, .accordion:hover {
                    background-color: #ccc;
                }
                .panel {
                    padding: 0 18px;
                    background-color: white;
                    max-height: 0;
                    overflow: hidden;
                    transition: max-height 0.2s ease-out;
                }
                td {
                    text-align: right;
                    padding: 0 0 0 16px;
                }
            </style>
        </head>
        <body>
        """
    }
}
