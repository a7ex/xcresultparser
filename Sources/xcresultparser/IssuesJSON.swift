//
//  IssuesJSON.swift
//
//  Created by Alex da Franca on 22.05.24.
//

import Foundation
import XCResultKit

/// Output some infos about warnings and issues
///
/// [Code Climate Specification](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md)
/// [Gitlab Code Climate Support](https://docs.gitlab.com/ee/ci/testing/code_quality.html#implement-a-custom-tool)
///
public struct IssuesJSON {
    let resultFile: XCResultFile
    let projectRoot: String
    let checkName: String
    let invocationRecord: ActionsInvocationRecord

    public init?(with url: URL, projectRoot: String = "") {
        resultFile = XCResultFile(url: url)
        guard let invocationRecord = resultFile.getInvocationRecord(),
              let checkdata = try? Data(contentsOf: url.appendingPathComponent("Info.plist")) else {
            return nil
        }
        self.invocationRecord = invocationRecord
        checkName = checkdata.md5()
        self.projectRoot = projectRoot
    }

    public func jsonString(format: OutputFormat, quiet: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData: Data
        if format == .errors {
            let errors = invocationRecord.issues.errorSummaries
                .map { Issue(issueSummary: $0, severity: .blocker, checkName: checkName, projectRoot: projectRoot) }
            jsonData = try encoder.encode(errors)
        } else {
            let warnings = invocationRecord.issues.warningSummaries
                .map { Issue(issueSummary: $0, severity: .minor, checkName: checkName, projectRoot: projectRoot) }
            let analyzerWarnings = invocationRecord.issues.analyzerWarningSummaries
                .map { Issue(issueSummary: $0, severity: .major, checkName: checkName, projectRoot: projectRoot) }
            var combined = warnings + analyzerWarnings
            if format == .warningsAndErrors {
                let errors = invocationRecord.issues.errorSummaries
                    .map { Issue(issueSummary: $0, severity: .blocker, checkName: checkName, projectRoot: projectRoot) }
                combined += errors
            }
            jsonData = try encoder.encode(combined)
        }
        return String(decoding: jsonData, as: UTF8.self)
    }
}
