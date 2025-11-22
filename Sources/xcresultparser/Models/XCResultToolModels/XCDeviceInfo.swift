//
//  XCDeviceInfo.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCDeviceInfo: Codable {
    let architecture: String // e.g. "arm64",
    let deviceId: String // e.g. 00008103-000959DC213B001E",
    let deviceName: String // e.g. "My Mac",
    let modelName: String // e.g. "iMac",
    let osVersion: String // e.g. "26.0.1",
    let osBuildNumber: String? // e.g. "25A362",
    let platform: String? // e.g. "macOS"
}
