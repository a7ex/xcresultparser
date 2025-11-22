//
//  XCBuildResults.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 02.11.25.
//

struct XCBuildResults: Codable {
    let destination: XCDeviceInfo
    let startTime: Double // Date as a UNIX timestamp (seconds since midnight UTC on January 1, 1970)
    let endTime: Double // Date as a UNIX timestamp (seconds since midnight UTC on January 1, 1970)
    let analyzerWarnings: [XCIssue]
    let warnings: [XCIssue]
    let errors: [XCIssue]
    let status: String?
    let analyzerWarningCount: Int
    let errorCount: Int
    let warningCount: Int
    let actionTitle: String?
}

extension XCBuildResults {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        destination = try values.decode(XCDeviceInfo.self, forKey: .destination)
        startTime = try values.decode(Double.self, forKey: .startTime)
        endTime = try values.decode(Double.self, forKey: .endTime)
        analyzerWarnings = try values.decode([XCIssue].self, forKey: .analyzerWarnings)
        warnings = try values.decode([XCIssue].self, forKey: .warnings)
        errors = try values.decode([XCIssue].self, forKey: .errors)
        status = try? values.decode(String.self, forKey: .status)
        analyzerWarningCount = (try? values.decode(Int.self, forKey: .analyzerWarningCount)) ?? 0
        errorCount = (try? values.decode(Int.self, forKey: .errorCount)) ?? 0
        warningCount = (try? values.decode(Int.self, forKey: .warningCount)) ?? 0
        actionTitle = try? values.decode(String.self, forKey: .actionTitle)
    }
}
