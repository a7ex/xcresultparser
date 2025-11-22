//
//  XCTestFailure.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

import Foundation

struct XCTestFailure: Codable {
    let testName: String
    let targetName: String
    let failureText: String
    let testIdentifier: Int64
    let testIdentifierString: String
    let testIdentifierURL: URL?
}

extension XCTestFailure {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        testName = try values.decode(String.self, forKey: .testName)
        targetName = try values.decode(String.self, forKey: .targetName)
        failureText = try values.decode(String.self, forKey: .failureText)
        testIdentifier = try values.decode(Int64.self, forKey: .testIdentifier)
        testIdentifierString = try values.decode(String.self, forKey: .testIdentifierString)
        let testIdentifierURLString = try? values.decode(String.self, forKey: .testIdentifierURL)
        if let testIdentifierURLString {
            testIdentifierURL = URL(string: testIdentifierURLString)
        } else {
            testIdentifierURL = nil
        }
    }
}
