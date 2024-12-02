//
//  DependencyFactory.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 01.12.24.
//

import Foundation

class DependencyFactory {
    static var createShell: () -> Commandline = {
        Shell()
    }
    static var createFileManager: () -> FileManaging = {
        FileManager.default
    }
}
