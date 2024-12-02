//
//  DependencyFactory.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 01.12.24.
//

import Foundation

class DependencyFactory {
    static var shell: Commandline = Shell()
    static var fileManager: FileManaging = FileManager.default
}
