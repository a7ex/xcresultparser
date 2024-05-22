//
//  IssuePositionData.swift
//
//  Created by Alex da Franca on 22.05.24.
//

import Foundation

struct IssuePositionData: Codable {
    /// The line on which the code quality violation occurred.
    let begin: PositionData
    let end: PositionData
}
