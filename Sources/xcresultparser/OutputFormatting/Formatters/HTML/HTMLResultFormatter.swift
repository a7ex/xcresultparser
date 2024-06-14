//
//  HTMLResultFormatter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 02.06.21.
//

import Foundation

public struct HTMLResultFormatter: XCResultFormatting {
    public init() {}

    public func documentPrefix(title: String) -> String {
        return htmlDocStart(with: title)
    }

    public var documentSuffix: String {
        return htmlDocEnd
    }

    public var accordionOpenTag: String {
        return "<div class=\"panel\">"
    }

    public var accordionCloseTag: String {
        return "</div>"
    }

    public var tableOpenTag: String {
        return "<table>"
    }

    public var tableCloseTag: String {
        return "</table>"
    }

    public var divider: String {
        return "<hr>"
    }

    public func resultSummaryLine(_ item: String, failed: Bool) -> String {
        let cssClass = failed ? "resultSummaryLineFailed" : "resultSummaryLineSuccess"
        return htmlParagraphXML(content: item, cssClass: cssClass)
    }

    public func resultSummaryLineWarning(_ item: String, hasWarnings: Bool) -> String {
        let cssClass = hasWarnings ? "resultSummaryLineWarning" : "resultSummaryLineSuccess"
        return htmlParagraphXML(content: item, cssClass: cssClass)
    }

    public func testConfiguration(_ item: String) -> String {
        return htmlNode("h2", content: item)
    }

    public func testTarget(_ item: String, failed: Bool) -> String {
        let cssClass = failed ? "testTargetFailed" : "testTargetSuccess"
        return htmlParagraphXML(content: item, cssClass: cssClass)
    }

    public func testClass(_ item: String, failed: Bool) -> String {
        let cssClass = failed ? "testClassFailed" : "testClassSuccess"
        let buttonContent = htmlSpan(content: item, cssClass: cssClass)
        return htmlButton(content: buttonContent, cssClass: "accordion")
    }

    public func singleTestItem(_ item: String, failed: Bool) -> String {
        let cssClass = failed ? "singleTestItemFailed" : "singleTestItemSuccess"
        return htmlParagraphXML(content: item, cssClass: cssClass)
    }

    public func failedTestItem(_ item: String, message: String) -> String {
        let buttonContent = htmlSpan(content: item, cssClass: "singleTestItemFailedWithMessage")
        let button = htmlButton(content: buttonContent, cssClass: "accordion")
        let msg = htmlParagraph(content: message, cssClass: "singleTestItemFailedMessage")
        return button + "\n" + htmlDiv(content: msg, cssClass: "panel")
    }

    public func codeCoverageTargetSummary(_ item: String) -> String {
        return htmlButton(content: item, cssClass: "accordion")
    }

    public func codeCoverageFileSummary(_ item: String) -> String {
        return htmlButton(content: item, cssClass: "accordion")
    }

    public func codeCoverageFunctionSummary(_ items: [String]) -> String {
        let tr = XMLElement(name: "tr")
        for item in items {
            tr.addChild(htmlElement("td", content: item))
        }
        return tr.xmlString(options: .documentTidyHTML)
    }

    // MARK: - Private

    private func htmlDiv(content: XMLElement, cssClass: String? = nil) -> String {
        return htmlNode("div", content: content, cssClass: cssClass)
    }

    private func htmlParagraphXML(content: String, cssClass: String? = nil) -> String {
        return htmlNode("p", content: content, cssClass: cssClass)
    }

    private func htmlParagraph(content: String, cssClass: String? = nil) -> XMLElement {
        return htmlElement("p", content: content, cssClass: cssClass)
    }

    private func htmlSpan(content: String, cssClass: String? = nil) -> XMLElement {
        return htmlElement("span", content: content, cssClass: cssClass)
    }

    private func htmlButton(content: String, cssClass: String? = nil) -> String {
        return htmlNode("button", content: content, cssClass: cssClass)
    }

    private func htmlButton(content: XMLElement, cssClass: String? = nil) -> String {
        return htmlNode("button", content: content, cssClass: cssClass)
    }

    private func htmlNode(_ nodeName: String, content: String, cssClass: String? = nil) -> String {
        return htmlElement(nodeName, content: content, cssClass: cssClass)
            .xmlString(options: .documentTidyHTML)
    }

    private func htmlNode(_ nodeName: String, content: XMLElement, cssClass: String? = nil) -> String {
        return htmlElement(nodeName, content: content, cssClass: cssClass)
            .xmlString(options: .documentTidyHTML)
    }

    private func htmlElement(_ nodeName: String, content: String, cssClass: String? = nil) -> XMLElement {
        let node = XMLElement(name: nodeName, stringValue: content)
        if let cssClass = cssClass {
            node.addAttribute(name: "class", stringValue: cssClass)
        }
        return node
    }

    private func htmlElement(_ nodeName: String, content: XMLElement, cssClass: String? = nil) -> XMLElement {
        let node = XMLElement(name: nodeName)
        if let cssClass = cssClass {
            node.addAttribute(name: "class", stringValue: cssClass)
        }
        node.addChild(content)
        return node
    }

    // swiftlint:disable:next function_body_length
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

    var htmlDocEnd: String {
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
            </body>
            </html>
            """
    }
}
