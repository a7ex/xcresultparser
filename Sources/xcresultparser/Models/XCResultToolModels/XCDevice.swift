//
//  XCDevice.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results metrics
// xcrun xcresulttool get test-results summary
// xcrun xcresulttool get test-results activities
// xcrun xcresulttool get test-results tests

struct XCDevice: Codable {
    let deviceId: String // e.g. 00008103-000959DC213B001E",
    let deviceName: String // e.g. "My Mac",

    // only required in 'xcrun xcresulttool get test-results activities'
    let architecture: String? // e.g. "arm64",
    let modelName: String? // e.g. "iMac",
    let osVersion: String? // e.g. "26.0.1",

    // optional
    let platform: String? // e.g. "macOS"
    let osBuildNumber: String? // e.g. "25A362",
}
