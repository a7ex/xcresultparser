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
        // An empty path would resolve to the current working directory.
        guard !path.isEmpty else {
            return false
        }
        let values = try? URL(filePath: path).resourceValues(forKeys: [.isDirectoryKey])
        return values?.isDirectory == true
    }
}
