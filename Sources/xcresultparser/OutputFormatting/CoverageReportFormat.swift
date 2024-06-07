//
//  CoverageReportFormat.swift
//
//  Created by nkokhelo mhlongo on 2024/05/31.
//

public enum CoverageReportFormat: String {
    case methods, classes, targets, totals
    public init(string: String?) {
        if let input = string?.lowercased(),
           let fmt = CoverageReportFormat(rawValue: input) {
            self = fmt
        } else {
            self = .methods
        }
    }
}
