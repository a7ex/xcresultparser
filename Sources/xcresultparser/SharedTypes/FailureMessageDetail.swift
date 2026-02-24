//
//  FailureMessageDetail.swift
//  xcresultparser
//

import Foundation

struct FailureMessageDetail {
    let message: String
    let documentLocation: String
}

extension FailureMessageDetail {
    init?(from raw: String) {
        let parts = raw.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            return nil
        }
        let file = String(parts[0])
        let line = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty, line.allSatisfy(\.isNumber) else {
            return nil
        }
        let msg = String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !file.isEmpty, !msg.isEmpty else {
            return nil
        }
        message = msg
        documentLocation = "\(file):\(line)"
    }
}
