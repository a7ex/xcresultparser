//
//  IssueLocation.swift
//
//  Created by Alex da Franca on 22.05.24.
//

import Foundation

struct IssueLocation: Codable, Equatable {
    /// The relative path to the file containing the code quality violation.
    let path: String
    let lines: IssueLocationData
    let positions: IssuePositionData
}

extension IssueLocation {
    static func == (lhs: IssueLocation, rhs: IssueLocation) -> Bool {
        return lhs.positions.begin.line == rhs.positions.begin.line &&
            lhs.positions.end.line == rhs.positions.end.line &&
            lhs.positions.begin.column == rhs.positions.begin.column &&
            lhs.positions.end.column == rhs.positions.end.column &&
            lhs.path == rhs.path
    }
}

extension IssueLocation {
    init(issueLocationInfo: IssueLocationInfo?, projectRoot: String = "") {
        guard let issueLocationInfo else {
            path = ""
            lines = IssueLocationData(begin: 0, end: 0)
            positions = IssuePositionData(
                begin: PositionData(line: 0, column: 0),
                end: PositionData(line: 0, column: 0)
            )
            return
        }
        path = issueLocationInfo.filePath.relativePath(relativeTo: projectRoot)
        lines = IssueLocationData(begin: issueLocationInfo.startLine, end: issueLocationInfo.endLine)
        positions = IssuePositionData(
            begin: PositionData(line: issueLocationInfo.startLine, column: issueLocationInfo.startColumn),
            end: PositionData(line: issueLocationInfo.endLine, column: issueLocationInfo.endColumn)
        )
    }
}

extension IssueLocation {
    var fingerprint: String {
        return "\(path)-\(positions.begin.line)-\(positions.begin.column)"
    }
}
