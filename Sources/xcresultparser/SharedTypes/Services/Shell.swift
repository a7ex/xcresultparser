//
//  Shell.swift
//
//
//  Created by Alex da Franca on 03.04.22.
//

import Foundation

protocol Commandline {
    func execute(program: String, with arguments: [String], at executionPath: URL?) throws -> Data

    /// Like `execute(program:with:at:)`, but terminates the program if the calling task is cancelled.
    func executeCancellable(program: String, with arguments: [String], at executionPath: URL?) async throws -> Data
}

extension Commandline {
    func execute(program: String, with arguments: [String]) throws -> Data {
        return try execute(program: program, with: arguments, at: nil)
    }

    /// Test doubles have no process to terminate.
    func executeCancellable(program: String, with arguments: [String], at executionPath: URL?) async throws -> Data {
        try execute(program: program, with: arguments, at: executionPath)
    }
}

struct Shell: Commandline {
    func execute(
        program: String,
        with arguments: [String],
        at executionPath: URL? = nil
    ) throws -> Data {
        try autoreleasepool {
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
            defer {
                try? outPipe.fileHandleForReading.close()
                try? errorPipe.fileHandleForReading.close()
            }
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
    }

    func executeCancellable(
        program: String,
        with arguments: [String],
        at executionPath: URL? = nil
    ) async throws -> Data {
        try Task.checkCancellation()
        let process = Process()
        if let directoryUrl = executionPath {
            process.currentDirectoryURL = directoryUrl
        }
        process.executableURL = URL(fileURLWithPath: program)
        process.arguments = arguments
        let errorPipe = Pipe()
        process.standardError = errorPipe
        let outPipe = Pipe()
        process.standardOutput = outPipe
        defer {
            try? outPipe.fileHandleForReading.close()
            try? errorPipe.fileHandleForReading.close()
        }
        try process.run()
        // Terminating the program closes its end of the pipe, which ends the blocking read.
        let data = await withTaskCancellationHandler {
            autoreleasepool {
                outPipe.fileHandleForReading.readDataToEndOfFile()
            }
        } onCancel: {
            process.terminate()
        }
        process.waitUntilExit()
        try Task.checkCancellation()
        let status = process.terminationStatus
        if status != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(decoding: errorData, as: UTF8.self)
            throw CLIError.executionError(code: Int(status), message: errorMessage)
        }
        return data
    }

    enum CLIError: Error {
        case executionError(code: Int, message: String)
    }
}
