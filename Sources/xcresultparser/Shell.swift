//
//  Shell.swift
//  
//
//  Created by Alex da Franca on 03.04.22.
//

import Foundation

struct Shell {
    static func execute(
        program: String,
        with arguments: [String],
        at executionPath: URL? = nil
    ) throws -> Data {
        let task = Process()
        if let directoryUrl = executionPath {
            task.currentDirectoryURL = directoryUrl
        }
        task.executableURL = URL(fileURLWithPath: program)
        task.arguments = arguments
        let errorPipe = Pipe()
        task.standardError = errorPipe
        let outPipe = Pipe()
        task.standardOutput = outPipe
        try task.run()
        let fileHandle = outPipe.fileHandleForReading
        let data = fileHandle.readDataToEndOfFile()
        task.waitUntilExit()
        let status = task.terminationStatus
        if status != 0 {
            let fileHandle = errorPipe.fileHandleForReading
            let data = fileHandle.readDataToEndOfFile()
            let errorMessage = String(decoding: data, as: UTF8.self)
            throw CLIError.executionError(code: Int(status), message: errorMessage)
        } else {
            return data
        }
    }

    enum CLIError: Error {
        case executionError(code: Int, message: String)
    }
}
