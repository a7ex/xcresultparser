//
//  XCActivityNode.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results activities

struct XCActivityNode: Codable {
    let title: String
    let isAssociatedWithFailure: Bool

    let startTime: Double? // Date as a UNIX timestamp (seconds since midnight UTC on January 1, 1970)
    let attachments: [XCAttachment]?
    let childActivities: [XCActivityNode]?
}

