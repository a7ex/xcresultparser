//
//  FileCoverage.swift
//
//  Created by maxwell-legrand on 15.05.24.
//

import Foundation

// FileCoverage information struct
struct FileCoverage: Decodable {
    let files: [String: [LineDetail]]

    // Custom initializer to handle the top-level dictionary
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var filesDict = [String: [LineDetail]]()

        for key in container.allKeys {
            let keyString = key.stringValue
            let lineDetails = try container.decode([LineDetail].self, forKey: key)
            filesDict[keyString] = lineDetails
        }
        files = filesDict
    }

    private struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            intValue = nil
        }

        init?(intValue: Int) {
            return nil
        }
    }
}
