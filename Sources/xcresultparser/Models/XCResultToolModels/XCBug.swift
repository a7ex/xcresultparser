//
//  XCBug.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 06.12.25.
//
// xcrun xcresulttool get test-results test-details

struct XCBug: Codable {
    let url: String?
    let identifier: String?
    let title: String?
}

