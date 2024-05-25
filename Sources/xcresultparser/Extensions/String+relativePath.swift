//
//  String+relativePath.swift
//
//  Created by Alex da Franca on 23.05.24.
//

import Foundation

extension String {
    func text(in range: NSRange) -> String {
        let idx1 = index(startIndex, offsetBy: range.location)
        let idx2 = index(idx1, offsetBy: range.length)
        return String(self[idx1 ..< idx2])
    }
    
    func relativePath(relativeTo projectRoot: String) -> String {
        guard !projectRoot.isEmpty else {
            return self
        }
        let projectRootTrimmed = projectRoot.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = components(separatedBy: "/\(projectRootTrimmed)")
        guard parts.count > 1 else {
            return self
        }
        let relative = parts[parts.count - 1]
        return relative.starts(with: "/") ?
            String(relative.dropFirst()) :
            relative
    }
}
