//
//  XCAttachment.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results activities

struct XCAttachment: Codable {
    let name: String
    let uuid: String
    let timestamp: Double // Date as a UNIX timestamp (seconds since midnight UTC on January 1, 1970)
    let payloadId: String?
    let lifetime: String?
}

