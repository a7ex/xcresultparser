//
//  FileManaging.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 01.12.24.
//

import Foundation
import SystemPackage

/// The file system queries JunitXML needs, so tests can replace them.
protocol FileManaging: Sendable {
    /// Whether a directory exists at `path`. An empty path is never a directory.
    func directoryExists(atPath path: String) -> Bool
}

extension FileManager: FileManaging {
    func directoryExists(atPath path: String) -> Bool {
        (try? FilePath(path).stat().type) == .directory
    }
}
