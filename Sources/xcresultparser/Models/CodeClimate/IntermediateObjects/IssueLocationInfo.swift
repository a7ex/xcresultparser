//
//  IssueLocationInfo.swift
//
//  Created by Alex da Franca on 22.05.24.
//

import Foundation
import XCResultKit

/// Helper object to convert from InvocationRecoord.DocumentLocation to Code Climate objects
///
struct IssueLocationInfo {
    let filePath: String
    let startLine: Int
    let endLine: Int
    let startColumn: Int
    let endColumn: Int

    init?(with documentLocation: DocumentLocation?) {
        guard let documentLocation,
              let url = URL(string: documentLocation.url) else {
            return nil
        }
        // documentLocation.concreteTypeName: "DVTTextDocumentLocation"
        filePath = url.path
        guard let fragment = url.fragment else {
            startLine = 0
            endLine = 0
            startColumn = 0
            endColumn = 0
            return
        }
        let pairs = fragment.components(separatedBy: "&")
        var startline = 0
        var endline = 0
        var startcolumn = 0
        var endcolumn = 0
        for pair in pairs {
            let location = pair.components(separatedBy: "=")
            guard location.count > 1 else { continue }
            switch location[0] {
            case "EndingColumnNumber":
                endcolumn = Int(location[1]) ?? 0
            case "EndingLineNumber":
                endline = Int(location[1]) ?? 0
            case "StartingColumnNumber":
                startcolumn = Int(location[1]) ?? 0
            case "StartingLineNumber":
                startline = Int(location[1]) ?? 0
            default:
                break
            }
        }
        startLine = startline
        endLine = endline
        startColumn = startcolumn
        endColumn = endcolumn
    }
}
