//
//  XCContent.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get content-availability --path example.xcresult

struct XCContent: Codable {
    let hasCoverage: Bool
    let hasDiagnostics: Bool
    let hasTestResults: Bool
    let logs: [XCLogType]
}

enum XCLogType: String, Codable {
    case build
    case action
}
