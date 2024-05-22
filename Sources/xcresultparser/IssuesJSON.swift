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
    let checkName: String
    let invocationRecord: ActionsInvocationRecord
    
    public init?(with url: URL) {
        resultFile = XCResultFile(url: url)
        guard let invocationRecord = resultFile.getInvocationRecord(),
              let checkdata = try? Data(contentsOf: url.appendingPathComponent("Info.plist")) else {
            return nil
        }
        self.invocationRecord = invocationRecord
        checkName = checkdata.md5()
    }
    
    public func jsonString(format: OutputFormat, quiet: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData: Data
        if format == .errors {
            let errors = invocationRecord.issues.errorSummaries
                .map { Issue(issueSummary: $0, severity: .blocker, checkName: checkName) }
            jsonData = try encoder.encode(errors)
        } else {
            let warnings = invocationRecord.issues.warningSummaries
                .map { Issue(issueSummary: $0, severity: .minor, checkName: checkName) }
            let analyzerWarnings = invocationRecord.issues.analyzerWarningSummaries
                .map { Issue(issueSummary: $0, severity: .info, checkName: checkName) }
            let combined = warnings + analyzerWarnings
            jsonData = try encoder.encode(combined)
        }
        return String(decoding: jsonData, as: UTF8.self)
    }
}
