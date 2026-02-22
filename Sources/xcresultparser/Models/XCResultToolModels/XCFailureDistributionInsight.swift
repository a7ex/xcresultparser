//
//  XCFailureDistributionInsight.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//
// xcrun xcresulttool get test-results insights

struct XCFailureDistributionInsight: Codable {
    let title: String
    let impact: Int
    let distributionPercent: Double
    let associatedTestIdentifiers: [String]

    // Optional
    let bug: String?
    let tag: String?
    let destinations: [XCDestination]?
}

extension XCFailureDistributionInsight {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        distributionPercent = try values.decode(Double.self, forKey: .distributionPercent)
        associatedTestIdentifiers = try values.decode([String].self, forKey: .associatedTestIdentifiers)
        impact = if let intImpact = try? values.decode(Int.self, forKey: .impact) {
            intImpact
        } else if let stringImpact = try? values.decode(String.self, forKey: .impact),
                  let parsedImpact = Int(stringImpact) {
            parsedImpact
        } else {
            0
        }
        bug = try? values.decode(String.self, forKey: .bug)
        tag = try? values.decode(String.self, forKey: .tag)
        destinations = try? values.decode([XCDestination].self, forKey: .destinations)
    }
}
