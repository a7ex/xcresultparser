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
    let excludedPaths: Set<String>

    public init?(
        with url: URL,
        projectRoot: String = "",
        excludedPaths: [String] = []
    ) {
        resultFile = XCResultFile(url: url)
        guard let invocationRecord = resultFile.getInvocationRecord(),
              let checkdata = try? Data(contentsOf: url.appendingPathComponent("Info.plist")) else {
            return nil
        }
        self.invocationRecord = invocationRecord
        checkName = checkdata.md5()
        self.projectRoot = projectRoot
        self.excludedPaths = Set(excludedPaths)
    }

    public func jsonString(format: OutputFormat, quiet: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData: Data
        if format == .errors {
            let errors = invocationRecord.issues.errorSummaries
                .compactMap {
                    Issue(
                        issueSummary: $0,
                        severity: .blocker,
                        checkName: checkName,
                        projectRoot: projectRoot,
                        excludedPaths: excludedPaths
                    )
                }
            jsonData = try encoder.encode(errors)
        } else {
            let warnings = invocationRecord.issues.warningSummaries
                .compactMap {
                    Issue(
                        issueSummary: $0,
                        severity: .minor,
                        checkName: checkName,
                        projectRoot: projectRoot,
                        excludedPaths: excludedPaths
                    )
                }
            let analyzerWarnings = invocationRecord.issues.analyzerWarningSummaries
                .compactMap {
                    Issue(
                        issueSummary: $0,
                        severity: .major,
                        checkName: checkName,
                        projectRoot: projectRoot,
                        excludedPaths: excludedPaths
                    )
                }
            var combined = warnings + analyzerWarnings
            if format == .warningsAndErrors {
                let errors = invocationRecord.issues.errorSummaries
                    .compactMap {
                        Issue(
                            issueSummary: $0,
                            severity: .blocker,
                            checkName: checkName,
                            projectRoot: projectRoot,
                            excludedPaths: excludedPaths
                        )
                    }
                combined += errors
            }
            jsonData = try encoder.encode(combined)
        }
        return String(decoding: jsonData, as: UTF8.self)
    }
}
