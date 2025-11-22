//
//  XCTestNode.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

import Foundation

struct XCTestNode: Codable {
    let children: [XCTestNode]
    let name: String // e.g. "xcresultparser",
    let nodeType: XCTestNodeType // e.g. "Test Plan",
    let result: XCTestResult? // e.g. "Passed"
    let nodeIdentifier: String? // e.g. "0"
    let nodeIdentifierURL: URL? // e.g. "test://com.apple.xcode/Xcresultparser/XcresultparserTests/XcresultparserTests"
    let durationInSeconds: TimeInterval? // e.g. 19
    let details: String?
    let tags: [String]
    // let duration: String // left out because we can format `durationInSeconds` as String ourselves ;-)
}

extension XCTestNode {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        // mandatory values:
        name = try values.decode(String.self, forKey: .name)
        nodeType = try values.decode(XCTestNodeType.self, forKey: .nodeType)

        // optional values:
        result = try? values.decode(XCTestResult.self, forKey: .result)
        nodeIdentifier = try? values.decode(String.self, forKey: .nodeIdentifier)
        let nodeIdentifierURLString = try? values.decode(String.self, forKey: .nodeIdentifierURL)
        if let nodeIdentifierURLString {
            nodeIdentifierURL = URL(string: nodeIdentifierURLString)
        } else {
            nodeIdentifierURL = nil
        }
        children = (try? values.decode([XCTestNode].self, forKey: .children)) ?? [XCTestNode]()
        durationInSeconds = try? values.decode(TimeInterval.self, forKey: .durationInSeconds)
        details = try? values.decode(String.self, forKey: .details)
        tags = (try? values.decode([String].self, forKey: .nodeIdentifier)) ?? [String]()
    }
}
