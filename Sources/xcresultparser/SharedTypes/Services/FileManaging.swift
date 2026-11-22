//
//  FileManaging.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 01.12.24.
//

import Foundation

/// The file system queries JunitXML needs, so tests can replace them.
protocol FileManaging: Sendable {
    /// Whether a directory exists at `path`. An empty path is never a directory.
    func directoryExists(atPath path: String) -> Bool
}

extension FileManager: FileManaging {
    func directoryExists(atPath path: String) -> Bool {
        guard !path.isEmpty else { return false }
        var candidate = path
        for depth in 0...Int(MAXSYMLINKS) {
            while candidate.count > 1 && candidate.hasSuffix("/") {
                candidate.removeLast()
            }
            let attributes = try? attributesOfItem(atPath: candidate)
            switch attributes?[.type] as? FileAttributeType {
            case .typeDirectory:
                return true
            case .typeSymbolicLink:
                guard depth < Int(MAXSYMLINKS),
                      let target = try? destinationOfSymbolicLink(atPath: candidate) else { return false }
                // Relative targets start at the link's parent. Preserve ".." so the
                // filesystem checks each preceding component as it traverses the path.
                let parent = candidate.lastIndex(of: "/").map { candidate[...$0] } ?? ""
                candidate = target.hasPrefix("/") ? target : parent + target
            default:
                return false
            }
        }
        return false
    }
}
