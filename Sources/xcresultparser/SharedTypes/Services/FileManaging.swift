//
//  FileManaging.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 01.12.24.
//

import Foundation

protocol FileManaging: Sendable {
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
}

extension FileManager: FileManaging {
    // just add protocol conformance to Foundation's FileManager
}
