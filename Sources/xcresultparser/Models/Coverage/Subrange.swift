//
//  Subrange.swift
//
//  Created by maxwell-legrand on 15.05.24.
//

import Foundation

// Subrange information struct
struct Subrange: Decodable {
    let column: Int
    let executionCount: Double
    let length: Int
}
