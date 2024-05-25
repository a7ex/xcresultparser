//
//  IssueCategory.swift
//
//  Created by Alex da Franca on 22.05.24.
//

import Foundation

enum IssueCategory: String, Codable {
    case bugRisk = "Bug Risk"
    case clarity = "Clarity"
    case compatibility = "Compatibility"
    case complexity = "Complexity"
    case duplication = "Duplication"
    case performance = "Performance"
    case security = "Security"
    case style = "Style"
}
