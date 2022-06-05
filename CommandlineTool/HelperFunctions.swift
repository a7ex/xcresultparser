//
//  HelperFunctions.swift
//  SwiftDTO
//
//  Created by Alex da Franca on 24.05.17.
//  Copyright © 2017 Farbflash. All rights reserved.
//

import Foundation

func writeToStdErrorLn(_ str: String) {
    writeToStdError("\(str)\n")
}

func writeToStdError(_ str: String) {
    let handle = FileHandle.standardError

    if let data = str.data(using: String.Encoding.utf8) {
        handle.write(data)
    }
}

func writeToStdOutLn(_ str: String) {
    writeToStdOut("\(str)\n")
}

func writeToStdOut(_ str: String) {
    let handle = FileHandle.standardOutput
    handle.write(Data("\(str)\n".utf8))
}
