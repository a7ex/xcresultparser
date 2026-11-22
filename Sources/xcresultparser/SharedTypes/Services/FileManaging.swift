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
        // A trailing slash requires the destination to be a directory. The filesystem
        // follows symbolic links and checks every component before traversing "..".
        return fileExists(atPath: path.hasSuffix("/") ? path : path + "/")
    }
}
