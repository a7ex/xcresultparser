//
//  XCConfiguration.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results metrics
// xcrun xcresulttool get test-results summary
// xcrun xcresulttool get test-results activities
// xcrun xcresulttool get test-results tests

/// Testplan configuration
struct XCConfiguration: Codable {
    let configurationId: String // e.g. "1"
    let configurationName: String // e.g. "Test Scheme Action"
}
