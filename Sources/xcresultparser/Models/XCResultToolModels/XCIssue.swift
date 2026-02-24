//
//  XCIssue.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCIssue: Codable {
    let issueType: String
    let message: String
    let targetName: String?
    let sourceURL: String?
    let className: String?
}
