//
//  XCTestNode.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//
// xcrun xcresulttool get test-results tests

import Foundation

struct XCTestNode: Codable {
    let name: String // e.g. "xcresultparser",
    let nodeType: XCTestNodeType // e.g. "Test Plan",
    let children: [XCTestNode]?
    let result: XCTestResult? // e.g. "Passed"
    let nodeIdentifier: String? // e.g. "0"
    let nodeIdentifierURL: URL? // e.g. "test://com.apple.xcode/Xcresultparser/XcresultparserTests/XcresultparserTests"
    let duration: String?
    let durationInSeconds: TimeInterval? // e.g. 19
    let details: String?
    let tags: [String]
    // let duration: String // left out because we can format `durationInSeconds` as String ourselves ;-)
}

extension XCTestNode {
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        // mandatory values:
        name = try values.decode(String.self, forKey: .name)
        nodeType = try values.decode(XCTestNodeType.self, forKey: .nodeType)

        // optional values:
        result = try? values.decodeIfPresent(XCTestResult.self, forKey: .result)
        nodeIdentifier = try? values.decodeIfPresent(String.self, forKey: .nodeIdentifier)
        let nodeIdentifierURLString = try? values.decodeIfPresent(String.self, forKey: .nodeIdentifierURL)
        nodeIdentifierURL = if let nodeIdentifierURLString {
            URL(string: nodeIdentifierURLString)
        } else {
            nil
        }
        children = (try? values.decodeIfPresent([XCTestNode].self, forKey: .children)) ?? [XCTestNode]()
        duration = try? values.decodeIfPresent(String.self, forKey: .duration)
        durationInSeconds = try? values.decodeIfPresent(TimeInterval.self, forKey: .durationInSeconds)
        details = try? values.decodeIfPresent(String.self, forKey: .details)
        tags = (try? values.decodeIfPresent([String].self, forKey: .tags)) ?? []
    }
}
