//
//  Issue.swift
//
//  Created by Alex da Franca on 22.05.24.
//

import Foundation
import XCResultKit

struct Issue: Codable {
    /// Required. A description of the code quality violation.
    let description: String
    /// Required. A unique name representing the static analysis check that emitted this issue.
    let checkName: String
    /// Optional. A unique, deterministic identifier for the specific issue being reported to allow a user to exclude it from future analyses. For example, an MD5 hash.
    let fingerprint: String
    /// Optional. A Severity string (info, minor, major, critical, or blocker) describing the potential impact of the issue found..
    let severity: IssueSeverity
    let engineName: String
    /// Required. A Location object representing the place in the source code where the issue was discovered.
    let location: IssueLocation
    /// Required. Must always be "issue".
    let type: IssueType
    /// Required. At least one category indicating the nature of the issue being reported.
    let categories: [IssueCategory]
    /// Optional. A markdown snippet describing the issue, including deeper explanations and links to other resources.
    let content: IssueContent
    
    enum CodingKeys: String, CodingKey {
        case description, fingerprint, severity, location, type, categories, content
        case checkName = "check_name"
        case engineName = "engine_name"
    }
}

extension Issue {
    init(issueSummary: IssueSummary, severity: IssueSeverity, checkName: String) {
        let issueLocationInfo = IssueLocationInfo(with: issueSummary.documentLocationInCreatingWorkspace)
        description = "\(issueSummary.issueType) - \(issueSummary.message)"
        self.checkName = checkName
        fingerprint = "\(issueSummary.issueType) - \(issueSummary.message)".md5()
        self.severity = severity
        engineName = issueSummary.producingTarget ?? ""
        location = IssueLocation(issueLocationInfo: issueLocationInfo)
        type = .issue
        categories = []
        content = IssueContent(body: "\(issueSummary.issueType) - \(issueSummary.message)")
    }
}

enum IssueType: String, Codable {
    case issue
}
